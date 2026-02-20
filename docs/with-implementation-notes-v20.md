# The With Programming Language — Implementation Notes

**Companion to:** Specification v5.2
**Status:** Non-normative. Guidance for compiler and runtime engineers.
**Scope:** Implementation strategies, trade-offs, and architectural
decisions that do not affect language semantics.

The spec defines *what* the language guarantees. This document explains
*how* to implement those guarantees efficiently.

---

## 1. Compiler Architecture Overview

### 1.1 Recommended Pipeline

```
Source → Lexer → Parser → AST
    → c_import Resolution (invoke cc -E, parse C headers, inject symbols)
    → Name Resolution
    → Type Checker (bidirectional, local inference)
    → Ephemeral Checker (post-type-check AST walk)
    → Borrow Checker (intra-procedural, NLL)
    → MIR Lowering (desugaring: with-blocks, generators, pattern matching)
    → Optimization
    → Code Generation (C backend or Cranelift for v1.0)
    → Linker (with c_import link directives)
```

### 1.2 Why C Codegen for v1.0

A C backend maximizes portability and iteration speed during early
development. The generated C is not intended to be human-readable.
Move to Cranelift or LLVM when performance of generated code becomes
the bottleneck (likely Phase 5+).

### 1.3 Compilation Units

Each module compiles independently. Type signatures at module boundaries
are explicit (no cross-module inference). This enables parallel
compilation and fast incremental builds.

---

## 2. Borrow Checker Implementation

The borrow checker is dramatically simpler than Rust's because:

1. References cannot be stored (no lifetime parameters)
2. References cannot escape except as ephemeral returns
3. All analysis is intra-procedural

### 2.1 Data Structures

```
Place = Variable(name)
      | FieldAccess(Place, field_name)
      | Deref(Place)
      | Index(Place, expr)

Borrow = {
    kind:      Shared | Exclusive
    place:     Place
    created:   ProgramPoint
    last_use:  ProgramPoint
    id:        BorrowId
}
```

### 2.2 Algorithm

```
fn check_function(func):
    // Phase 1: Compute NLL ranges (borrow start → last use)
    let ranges = compute_nll_ranges(func)

    // Phase 2: At each program point, check for conflicts
    for point in func.program_points():
        let active = borrows_active_at(ranges, point)

        for (b1, b2) in active where b1.place overlaps b2.place:
            if b1.kind == Exclusive or b2.kind == Exclusive:
                EMIT ERROR

        if point is a move of place P:
            for b in active where b.place overlaps P:
                EMIT ERROR
```

### 2.3 NLL Range Computation

For each borrow, find the last use of the borrowed reference. Walk
the CFG forward from the borrow creation point, tracking all reads
of the reference variable.

Key rules:
- A function call receiving a reference is a use point. The borrow
  does NOT extend beyond the call (callee cannot store it).
- For ephemeral returns: the returned value is conservatively treated
  as borrowing from ALL reference parameters. The last use of the
  returned value extends the borrows of all inputs.
- If a reference is passed to multiple function calls, each call is
  an independent use point.

### 2.4 Overlap Analysis

```
fn places_overlap(a: Place, b: Place) -> bool:
    // FieldAccess: disjoint if names differ at same nesting level
    //   world.positions vs world.velocities → NO overlap
    //   world.positions vs world.positions.x → OVERLAP (prefix)
    //
    // Index: conservative overlap with ANY index on same base
    //   arr[i] vs arr[j] → OVERLAP (even constant indices)
    //
    // Prefix: x overlaps x.field (parent overlaps child)
```

Struct field disjointness is guaranteed at arbitrary nesting depth.
Array index disjointness is never assumed (use `get2_mut` or
`split_at_mut` for safe simultaneous access).

### 2.5 Cross-Function Boundaries

When a function returns an ephemeral value, the caller sees only:
"this return value borrows from some or all reference parameters."

The caller does not need to know *which* parameter is actually
borrowed — it treats all of them conservatively. This is less
precise than Rust but eliminates the need for lifetime annotations.

The precision loss is small in practice. It occasionally forces a
programmer to restructure code (e.g., take one reference parameter
instead of two), but this is rare and the error messages are clear.

---

## 3. Ephemeral Type Checker

Post-type-check AST walk. No dataflow analysis required.

### 3.1 Rules

| # | Rule | Action |
|---|------|--------|
| 1 | `&T`, `&mut T`, `StrView`, `Span[T]`, `SpanMut[T]` | Mark ephemeral |
| 2 | Type declared `ephemeral` | Mark ephemeral |
| 3 | Generic `F[T]` where `T` is ephemeral | Mark ephemeral |
| 4 | Struct with ephemeral field, not marked `ephemeral` | Reject definition |
| 5 | `let x = expr` where expr is ephemeral | Mark `x` ephemeral |
| 6 | Struct field of ephemeral type | Reject |
| 7 | Container insertion of ephemeral value | Reject |
| 8 | Function returning ephemeral | Callers inherit restriction |
| 9 | Escaping closure capturing ephemeral | Reject |
| 10 | `with` block result is ephemeral | Reject |

### 3.2 Implementation Notes

The checker walks the AST once, maintaining a set of "ephemeral"
bindings per scope. It does not need fixpoint iteration because
ephemerality is structural (determined by types, not by data flow).

For Rule 8: when analyzing a function call, check if the callee's
return type is ephemeral. If so, the binding receiving the result is
marked ephemeral. If the current function returns this binding, the
current function's return type must also be ephemeral (or it's an error).

---

## 4. `with` Block Lowering

### 4.1 Form Dispatch

At compile time, the compiler checks whether the expression's type
implements `Scoped` or `ScopedMut`:

```
fn lower_with(expr, name, is_mut, body):
    let ty = typeof(expr)
    if is_mut and ty implements ScopedMut:
        return lower_guarded_mut(expr, name, body)
    else if (not is_mut) and ty implements Scoped:
        return lower_guarded(expr, name, body)
    else if is_mut:
        return lower_binding_mut(expr, name, body)
    else:
        return lower_binding(expr, name, body)
```

### 4.2 Guarded Form (Scoped trait)

```
with lock.read() as data:
    body(data)
// →
lock.read().enter(|data| body(data))

with a.read() as x, b.write() as mut y:
    compute(x, y)
// →
a.read().enter(|x| b.write().enter_mut(|y| compute(x, y)))
```

### 4.3 Binding Form (no Scoped trait)

```
// Immutable binding
with expr as name: body
// → { let name = expr; body }

// Mutable binding (builder pattern)
with expr as mut name: body
// → { var name = expr; body }
```

These are trivial desugaring. The binding forms do not involve
closures, so non-local control flow (`return`, `break`, `continue`,
`?`) works automatically with no special handling.

### 4.4 Non-Local Return Implementation (Guarded Form Only)

The guarded form desugars to a closure, requiring special handling
for non-local control flow.

The desugared closure returns a tagged result:

```
enum WithFlow[R, Ret, Err] =
    | Complete(R)        // normal completion
    | Return(Ret)        // non-local return from enclosing function
    | Break              // break from enclosing loop
    | Continue           // continue in enclosing loop
    | Propagate(Err)     // ? error propagation
```

The compiler wraps control flow statements inside `with` blocks:
- `return val` → closure returns `WithFlow.Return(val)`
- `break` → closure returns `WithFlow.Break`
- `continue` → closure returns `WithFlow.Continue`
- `expr?` → on error, closure returns `WithFlow.Propagate(err)`

At the `enter` call site, the compiler generates a match:

```
match lock.read().enter(|data| { ... }) {
    Complete(r) -> r
    Return(v)   -> return v
    Break       -> break
    Continue    -> continue
    Propagate(e) -> return Err(e.into())
}
```

This is entirely a compile-time transformation. The `WithFlow` enum
is never exposed to user code. The runtime cost is one branch on
the happy path (checking for `Complete`).

**Alternative:** For v1.0 simplicity, the compiler can inline the
`enter` call entirely, replacing the closure with direct code in the
enclosing scope. This avoids the tagged-return mechanism at the cost
of requiring `enter` implementations to be inlineable. Since all
standard library `Scoped` implementations are trivial (lock, read,
call closure, unlock), this is always possible.

---

## 5. Generator Compilation

### 5.1 State Machine Transformation

A generator:

```
gen fn countdown(from: i32) -> i32 =
    var i = from
    while i >= 0:
        yield i
        i -= 1
```

Compiles to a struct + `next()` method:

```
type CountdownState = {
    state: u8        // which yield point we're at
    i: i32           // captured local
}

fn countdown(from: i32) -> CountdownState =
    CountdownState { state: 0, i: from }

impl Iter[i32] for CountdownState {
    fn next(self: &mut Self) -> Option[i32] =
        loop:
            match self.state
                0 ->
                    if self.i >= 0:
                        self.state = 1
                        return Some(self.i)
                    else:
                        return None
                1 ->
                    self.i -= 1
                    self.state = 0
}
```

### 5.2 Key Properties

- Each `yield` becomes a state transition.
- Local variables become fields of the state struct.
- The state struct size equals the maximum live locals across
  all yield points.
- No heap allocation unless the user explicitly boxes the iterator.
- Generators that capture references have ephemeral state structs.

---

## 6. `async`/`.await` Compilation

### 6.1 `async fn` Lowering

```
async fn fetch(url: str) -> Result[String, IoError] = body
```

Compiles to:

```
fn fetch(url: str) -> Task[Result[String, IoError]] =
    runtime::spawn_fiber(move || { body })
```

The closure captures all parameters by move. The runtime allocates
a fiber, assigns it a stack from the pool, and begins execution.

### 6.2 `.await` Lowering

```
let result = expr.await
```

Compiles to:

```
let result = runtime::fiber_block_on(expr)
```

`fiber_block_on` checks if the task is complete. If not, it:
1. Saves the current fiber's stack pointer and program counter
2. Marks the fiber as "waiting on task X"
3. Yields to the scheduler
4. (When task X completes, scheduler resumes this fiber)

### 6.3 `no_runtime` Gate

The compiler maintains a `runtime_available` flag from the build
configuration. In `no_runtime` builds:

- Any `async fn` declaration → compile error
- Any `.await` expression → compile error
- `spawn` → compile error
- `async scope` → compile error

Error message:

```
ERROR: `async` requires the fiber runtime.
       Add `runtime = true` to with.toml or remove `#[no_runtime]`.
       For OS-thread concurrency, use `thread.spawn_os` and `scope`.
```

---

## 7. Fiber Runtime Architecture

### 7.1 Core Components

```
Scheduler
├── WorkStealingPool (N OS threads)
├── FiberQueue (per-thread run queues)
├── IoReactor (epoll/kqueue/io_uring integration)
├── TimerHeap (for timeout operations)
└── StackPool (reusable fiber stacks)
```

### 7.2 Scheduler Loop (per OS thread)

```
loop:
    // 1. Check for completed I/O
    poll_io_reactor(timeout: 0)

    // 2. Run ready fibers
    while let Some(fiber) = local_queue.pop() or steal():
        switch_to_fiber(fiber)
        // fiber runs until it awaits, completes, or yields

    // 3. If no work, park on I/O reactor
    poll_io_reactor(timeout: infinity)
```

### 7.3 Fiber States

```
FiberState =
    | Ready                // can be scheduled
    | Running              // currently executing on an OS thread
    | Suspended(WaitingOn) // blocked on a Task, I/O, timer, or channel
    | Completed(Value)     // finished, result available
    | Cancelled            // cooperative cancellation in progress
```

---

## 8. Fiber Stack Strategies

This is the critical implementation section. The spec guarantees that
fibers behave as if they have real stacks. The implementation is free
to use any strategy that preserves observable semantics.

### 8.1 The Problem

A naive implementation allocates a fixed stack per fiber. At scale
(using the spec's 8KB initial allocation as baseline):

```
100K fibers × 8KB  = 800MB
  1M fibers × 8KB  = 8GB
```

Rust's stackless futures use ~100-200 bytes each:

```
100K futures × 200B = 20MB
  1M futures × 200B = 200MB
```

The gap is 20-40x. For game engines and typical servers (thousands of
fibers), this is negligible. For high-connection-count servers (100K+),
it matters.

### 8.2 Strategy 1: Fixed Stacks (Prototype)

Allocate a fixed-size stack per fiber. Simple and correct.

**Use for:** v1.0 prototype. Get the language working first.

```
Stack size:     8KB default (spec: 8KB initial, 64KB max growable)
Allocation:     mmap per fiber (or pool)
100K fibers:    ~800MB (worst case; suspended fibers often < 2KB)
Overhead:       None (no prologue checks)
Complexity:     Minimal
```

Note: the spec defines 64KB as the default maximum stack and 8KB as
the initial allocation. For a fixed-stack prototype, 8KB is a
reasonable starting point. The v1.0 phasing table targets segmented
stacks with 8KB initial (see §8.3).

### 8.3 Strategy 2: Segmented / Growable Stacks

Start with a small stack (256-512 bytes). Grow on demand by
allocating new segments.

**Use for:** v1.x when memory is a concern but compiler complexity
should remain low.

```
Initial size:   512 bytes
Growth:         Exponential (512 → 1K → 2K → 4K → ...)
100K fibers:    ~50MB (most fibers stay small)
Overhead:       Prologue check per function call (~1-2 instructions)
Complexity:     Moderate (segment management, cross-segment references)
```

This is what Go used initially (Go 1.0-1.3). Go later switched to
copyable stacks (possible because Go has a GC that can update
pointers). Without a GC, segmented stacks remain viable but have
a known "hot split" problem: a function near a segment boundary
that is called repeatedly may allocate and free segments on every
call. Mitigation: hysteresis (don't free a segment immediately
after returning from it).

### 8.4 Strategy 3: Virtual Memory Overcommit

Reserve a large virtual address range per fiber (e.g., 1MB). Commit
physical pages on demand via the OS.

**Use for:** Hosted 64-bit targets where VM space is abundant.

```
Reserved:       1MB virtual per fiber
Committed:      Only pages actually touched (usually 1-2 pages)
100K fibers:    100GB virtual (cheap), ~400MB-800MB physical
Overhead:       None (no prologue checks)
Complexity:     Low (OS handles it)
Limitation:     Minimum 1 page (4KB) per fiber that runs at all
```

Simple and effective on Linux/macOS. Does not work on embedded
targets or systems without virtual memory.

### 8.5 Strategy 4: Hybrid Stackful/Stackless (Production)

The most sophisticated approach. This closes the memory gap to
near-parity with Rust's stackless futures.

**Core idea:** Fibers use a real stack while *running*. When they
*suspend* at an `await`, the compiler saves only the live local
variables into a small heap-allocated state struct and returns the
stack to a shared pool.

```
Running fibers:   N stacks × configurable size (N = OS thread count)
Suspended fibers: state struct only (~100-500 bytes typical)

N = 16 OS threads, 1MB stacks = 16MB for running fibers
100K suspended fibers × 300B    = 30MB for state
Total:                          ≈ 46MB
```

Compare: 400MB for fixed stacks, 20MB for Rust futures.

**How it works:**

1. Fiber is scheduled. Scheduler assigns it a stack from the pool.
2. Fiber executes normally on the real stack.
3. Fiber hits `await`. Compiler-generated code:
   a. Saves all live locals into a heap-allocated state struct.
   b. Returns the stack to the pool.
   c. Fiber enters `Suspended` state with only the state struct.
4. Awaited operation completes. Scheduler:
   a. Assigns a (possibly different) stack from the pool.
   b. Restores live locals from the state struct onto the stack.
   c. Resumes execution.

**What the compiler must do at each `await` point:**

Classify all live values:

| Value type | Save action | Restore action |
|------------|-------------|----------------|
| Owned value (stack local) | Copy into state struct | Copy back to stack |
| Reference to heap/parameter | Save raw pointer | Restore raw pointer |
| Reference to stack local | Promote target to state struct; save as offset | Restore target; recompute reference |

**Why this is feasible in With (and would be extremely hard in Rust):**

With's ephemeral reference rules guarantee that at any `await` point:

- No external code has a pointer into this fiber's stack (references
  are second-class and cannot be stored).
- The compiler has perfect knowledge of all live references and what
  they point to (intra-procedural borrow checker).
- No references have leaked to other threads (ephemeral types are
  not `Send`).

This means the compiler can safely relocate stack locals to a state
struct without invalidating any references — because it can rewrite
ALL references (there are no unknown aliases).

In Rust, this is the problem that necessitated `Pin`: a self-referential
Future struct can't be moved because external code might hold a pointer
into it. In With, no external code can hold such a pointer.

**Complexity:** High. Requires compiler support at every `await` point
to analyze live variables and generate save/restore code. Recommend
implementing this in Phase 7 (optimization) after the language is
stable.

### 8.6 Recommended Phasing

| Phase | Strategy | Memory @ 100K fibers |
|-------|----------|---------------------|
| Prototype (v0.1) | Fixed 8KB stacks | ~800MB |
| Early release (v1.0) | Segmented stacks (8KB initial, growable) | ~50–200MB |
| Optimization (v1.x) | VM overcommit (hosted) + segmented (embedded) | ~50–200MB |
| Production (v2.0) | Hybrid stackful/stackless | ~46MB |

Each phase is a pure runtime change. No language semantics change.
No user code changes. This is the key advantage of specifying the
language in terms of "fibers with real stacks" — the implementation
is free to evolve.

### 8.7 Fiber Stack Pool

Maintain a per-thread free-list of stack segments keyed by size
(8 KB, 64 KB, 512 KB). Allocation is O(1) when the pool is
non-empty. This avoids `malloc` overhead on the hot path (fiber
spawn/exit). Pool size is configurable via `with.toml`.

### 8.8 Integration with Borrow Checker

The borrow checker does **not** need special handling for `await`
points. Because fibers have real stacks, borrows active across
`await` points are simply borrows that span the relevant program
points in the NLL analysis — no different from borrows spanning
any other function call. This is one of the key simplicity
advantages of the fiber model over state-machine futures.

---

## 9. Pattern Match Compilation

### 9.1 Decision Trees

Pattern matching compiles to decision trees, not sequential
if-else chains. The compiler builds a tree that tests each
discriminant at most once.

### 9.2 Exhaustiveness Checking

Use the standard algorithm: represent the pattern space as a matrix,
compute "usefulness" of each row, and report missing patterns.

For nested patterns, recursively decompose constructors. For guards,
treat the guarded arm as non-exhaustive (guards may fail at runtime).

### 9.3 Or-Patterns

`A | B -> body` compiles to: test for A, jump to body; test for B,
jump to body. The body is emitted once and shared.

---

## 10. Record Update Lowering

```
let p2 = { p1 with x: 3.0 }
```

For Copy types:
```
let p2 = p1           // copy all fields
p2.x = 3.0            // overwrite
```

For non-Copy types:
```
let p2_y = move p1.y  // move each non-overwritten field
let p2 = Point { x: 3.0, y: p2_y }
// p1 is now partially moved → invalid
```

The compiler must track partial moves through record update syntax.

---

## 11. Tail Call Optimization

### 11.1 `@[tailrec]` Verification

At the MIR level, verify that every recursive call in a `@[tailrec]`
function is in tail position:

- The call's result is directly returned (no wrapping, no further
  computation).
- The call is not inside a `defer` scope (defer runs after the call,
  breaking tail position).
- The call is not inside a `with` block (the closure boundary
  prevents TCO).

If verification fails, emit an error pointing at the non-tail call.

### 11.2 Lowering

Replace the tail call with: assign arguments to parameters, jump to
function entry. This becomes a loop in the generated code.

For mutual recursion: the compiler must merge the functions into a
single dispatch loop with a state tag.

---

## 12. Error Type Lowering

```
error AppError from IoError, ParseError
```

Generates:

```
type AppError =
    | Io(IoError)
    | Parse(ParseError)

impl From[IoError] for AppError {
    fn from(e: IoError) -> AppError = AppError.Io(e)
}

impl From[ParseError] for AppError {
    fn from(e: ParseError) -> AppError = AppError.Parse(e)
}
```

The `?` operator on `Result[T, E]` where the function returns
`Result[T, F]` and `F: From[E]` compiles to:

```
match expr {
    Ok(v)  -> v
    Err(e) -> return Err(F.from(e))
}
```

---

## 13. Monomorphization

### 13.1 Strategy

All generic functions are monomorphized (specialized for each concrete
type argument). No runtime dispatch unless the user explicitly writes
`dyn Trait`.

### 13.2 Code Size

Monomorphization can cause code bloat. Mitigations:

- Identical monomorphizations are deduplicated.
- Functions that don't use the type parameter in their body can be
  shared.
- The linker's identical code folding (ICF) catches remaining
  duplicates.

### 13.3 Compilation Speed

Monomorphization happens late in the pipeline (after type checking
and borrow checking operate on the generic version). This avoids
re-analyzing each specialization.

---

## 14. C Backend Code Generation

### 14.1 Mapping

| With concept | C output |
|---|---|
| Struct | C struct |
| Enum | Tagged union (tag + union of payloads) |
| Function | C function |
| Closure | Struct (captured vars) + function pointer |
| Generic | Separate C function per monomorphization |
| Move | memcpy + null source (debug) |
| Drop | Call destructor function before scope exit |
| Borrow check | Erased (compile-time only) |
| Ephemeral check | Erased (compile-time only) |

### 14.2 Fiber Runtime in C

The fiber scheduler can be implemented using:
- `ucontext` (POSIX, portable)
- Assembly context switch (faster, platform-specific)
- `setjmp`/`longjmp` (limited but simple)

For v1.0, use `ucontext` on POSIX and Fiber API on Windows.

---

## 15. Diagnostics

### 15.1 Error Message Quality

Error messages are a primary UX concern. Every compile error should:
1. State what is wrong
2. Point to the exact location
3. Explain why the rule exists
4. Suggest a fix

### 15.2 Key Diagnostic Scenarios

**Ephemeral escape:**
```
error[E0301]: ephemeral value cannot be stored in struct
  --> src/main.w:15:5
   |
15 |     type Bad = { view: StrView }
   |                  ^^^^^^^^^^^^^ StrView is ephemeral
   |
   = help: use owned `String` or `BufSlice` instead
   = note: ephemeral types cannot be stored because they may
           reference data that is freed when the scope exits
```

**Borrow conflict:**
```
error[E0101]: conflicting borrows of `data`
  --> src/main.w:8:9
   |
 6 |     let r = &mut data
   |             --------- exclusive borrow created here
 7 |     let s = &data
   |             ^^^^^ shared borrow conflicts
 8 |     *r = 10
   |     --- exclusive borrow used here
   |
   = help: use `r` before creating `s`, or restructure to
           avoid simultaneous access
```

**Async without runtime:**
```
error[E0501]: `async` requires the fiber runtime
  --> src/main.w:3:1
   |
 3 | async fn fetch(url: str) -> String =
   | ^^^^^^^^ not available in no_runtime builds
   |
   = help: add `runtime = true` to with.toml
   = help: for OS-thread concurrency, use `thread.spawn_os`
```

**`.await` inside `@[no_await_guard]` guard:**
```
error[E0701]: `.await` inside `@[no_await_guard]` with block
  --> src/service.w:15:20
   |
14 |     with self.cache.lock() as data:
   |          ------------------- MutexGuard is @[no_await_guard]
15 |         let result = fetch(data.url).await
   |                                      ^^^^^^ cannot .await while this guard is held
   |
   = note: MutexGuard blocks other fibers while held
   = help: clone data out of the guard, then .await:
           let url = with self.cache.lock() as data:
               data.url.clone()
           fetch(url).await
   = note: this restriction only applies to @[no_await_guard] types
           (Mutex, RwLock, Arena guards). Connection pools, transactions,
           and file handles are not affected.
```

**Unused Result:**
```
error[E0802]: unused `Result` — error may be silently swallowed
  --> src/main.w:8:5
   |
 8 |     db.execute("DROP TABLE users")
   |     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Result[Unit, DbError] unused
   |
   = help: propagate with `?`, handle with match, or discard with
           `let _ = ...`
```

**Unused Task:**
```
error[E0801]: unused `Task` will be cancelled on drop
  --> src/service.w:42:9
   |
42 |     send_analytics("page_view")
   |     ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Task created but not used
   |
   = note: dropping a Task cancels the fiber cooperatively
   = help: use `let _ = ...` to discard, or `spawn` for fire-and-forget
```

**Unnecessary unsafe block:**
```
error[E0901]: unnecessary `unsafe` block
  --> src/main.w:5:5
   |
 5 |     unsafe { let x = 1 + 2 }
   |     ^^^^^^ no unsafe operations in this block
   |
   = help: remove the `unsafe` wrapper
```

**Implicit numeric narrowing:**
```
error[E0201]: implicit narrowing conversion from `i64` to `i32`
  --> src/main.w:3:22
   |
 3 |     let small: i32 = big
   |                       ^^^ `i64` cannot be implicitly narrowed
   |
   = help: use explicit cast: `big as i32`
```

**Unreachable code:**
```
error[E0601]: unreachable code
  --> src/main.w:4:5
   |
 3 |     return 42
   |     --------- any code after this is unreachable
 4 |     println("hello")
   |     ^^^^^^^^^^^^^^^^ this code will never execute
```

**Closure treated as escaping:**
```
error[E0401]: closure captures ephemeral value but may escape
  --> src/main.w:12:13
   |
10 |     with store.read() as data:
   |                          ---- ephemeral borrow starts here
11 |         let view = data.get_view()
12 |         let f = |x| view.contains(x)
   |                 ^^^^ closure bound to variable is escaping
   |
   = note: closures bound to named variables are conservatively
           treated as escaping in v1.0, even if analysis could
           prove otherwise
   = help: use the closure directly as an argument:

           // instead of:
           let f = |x| view.contains(x)
           items |> filter(f)

           // write:
           items |> filter(|x| view.contains(x))

   = help: if the closure does not capture any ephemeral values,
           this error will not occur — check what the closure captures
```

---

## 16. `c_import` Implementation (Phase 0 Priority)

This is the highest-priority implementation task after the basic
compiler pipeline. Without `c_import`, the language cannot access
libc, cannot write to stdout, cannot allocate memory, and cannot
test against real-world C libraries. Every other feature depends on
this.

### 16.1 Architecture

```
c_import("sqlite3.h", link: "sqlite3")
         │
         ▼
┌─────────────────────┐
│  C Preprocessor     │  cc -E -D... -I... sqlite3.h
│  (system cc)        │
└────────┬────────────┘
         │ preprocessed C source
         ▼
┌─────────────────────┐
│  C Header Parser    │  Parse declarations (not bodies)
│  (in With compiler) │
└────────┬────────────┘
         │ C declarations (functions, structs, enums, typedefs, macros)
         ▼
┌─────────────────────┐
│  Type Mapper        │  Map C types → With types
└────────┬────────────┘
         │ With-native declarations
         ▼
┌─────────────────────┐
│  Module Injector    │  Inject as a With module
└────────┬────────────┘
         │
         ▼
  Available as normal With symbols (under `unsafe`)
```

### 16.2 C Preprocessor Invocation

The compiler invokes the system C compiler in preprocessing mode:

```
cc -E -dM \
   -I /usr/include \
   -I /usr/local/include \
   ${user_include_paths} \
   ${user_defines} \
   input_header.h \
   > preprocessed.c
```

`-E` produces preprocessed source (declarations without macros).
`-dM` dumps all `#define` macros separately.

The C compiler to use and additional flags come from `with.toml`
or can be auto-detected from the environment.

**Cross-compilation:** When cross-compiling, the C compiler must
match the target. `with.toml` supports per-target configuration:

```toml
[c_import.target."aarch64-linux"]
cc = "aarch64-linux-gnu-gcc"
include_paths = ["/usr/aarch64-linux-gnu/include"]
```

### 16.3 C Header Parser

The With compiler needs a C declaration parser. This does NOT need
to be a full C compiler. It needs to parse:

- Function declarations (not bodies)
- Struct and union definitions
- Enum definitions
- Typedef declarations
- Global variable declarations

It does NOT need to parse:
- Function bodies
- Expressions (except in enum initializers and macro constants)
- Preprocessor directives (already expanded)
- C++ (not supported)

**Implementation options (in order of recommendation):**

1. **Use libclang.** Link against libclang and use its AST to
   extract declarations. This is what Zig does. It is the most
   correct approach and handles edge cases (bitfields, flexible
   array members, `__attribute__`s, compiler extensions). The
   cost is a dependency on LLVM/Clang libraries.

2. **Use tree-sitter-c.** Parse with tree-sitter's C grammar,
   then walk the syntax tree to extract declarations. Lighter
   than libclang, but less accurate on compiler extensions.

3. **Write a minimal C declaration parser.** Only parse the subset
   of C that appears in header files post-preprocessing. Viable
   for a prototype but will hit edge cases quickly with real-world
   headers (especially system headers with GNU extensions).

**Recommendation:** Use libclang for v1.0. The correctness benefit
on real-world headers (POSIX, Windows, OpenSSL, SQLite) outweighs
the dependency cost. Zig proved this approach works at scale.

### 16.4 Type Mapping

| C type | With type |
|--------|-----------|
| `char` | `i8` (or `u8` on platforms where char is unsigned) |
| `short` | `i16` |
| `int` | `i32` |
| `long` | platform-dependent (`i32` or `i64`) |
| `long long` | `i64` |
| `unsigned int` | `u32` |
| `float` | `f32` |
| `double` | `f64` |
| `size_t` | `usize` |
| `void*` | `*mut void` |
| `const char*` | `*const u8` |
| `T*` | `*mut T` |
| `const T*` | `*const T` |
| `T[N]` | `[T; N]` (fixed-size array) |
| `struct S` | `type S = { ... } with repr(C)` |
| `union U` | `type U = union { ... } with repr(C)` |
| `enum E` | Integer constants (C enums are ints) |
| `typedef T name` | `type name = T` |
| `void` (return) | `Unit` |
| function pointer | `extern "C" fn(args) -> ret` |

**Opaque types:** C headers often declare `struct Foo;` without a
body. These become opaque types in With — zero-sized, usable only
as pointer targets (`*mut Foo`, `*const Foo`).

### 16.5 Macro Translation

After preprocessing with `-dM`, the compiler receives all macro
definitions. Classification:

| Macro form | Action |
|------------|--------|
| `#define NAME integer` | `const NAME: i32 = integer` |
| `#define NAME float` | `const NAME: f64 = float` |
| `#define NAME "string"` | `const NAME: *const u8 = "string"` |
| `#define NAME (cast)0` | Recognized as null / zero |
| `#define NAME other_name` | `const NAME = other_name` (alias) |
| `#define F(a,b) expr` | Best-effort: `fn F(a: auto, b: auto) = expr` |
| Complex macros | Warning + skip |

The compiler should track which macros are actually used in practice
(e.g., `SQLITE_OK`, `O_RDONLY`, `MAP_SHARED`) and prioritize
translating common patterns correctly.

### 16.6 Caching

Parsing system headers is expensive. The compiler should cache the
parsed result:

```
~/.cache/with/c_import/
    sqlite3.h_${hash_of_preprocessed_output}.cache
```

The cache key includes: header content hash, all include paths,
all defines, target triple, and C compiler version. Any change
invalidates the cache.

### 16.7 Error Handling

If `c_import` fails (header not found, parse error), the compiler
error must be clear:

```
error[E1001]: c_import failed for "nonexistent.h"
  --> src/main.w:1:5
   |
 1 | use c_import("nonexistent.h")
   |     ^^^^^^^^^^^^^^^^^^^^^^^^^ header not found
   |
   = help: verify the header exists in system include paths
   = help: add include paths in with.toml under [c_import]
   = note: searched: /usr/include, /usr/local/include
```

### 16.8 What Zig Teaches Us

Zig's `@cImport` is the gold standard. Key lessons:

1. **It works on day one.** Zig could import and use libc headers
   from its earliest releases. This made the language immediately
   useful for real work.

2. **libclang is worth the dependency.** Zig uses libclang (via
   its LLVM dependency) and this handles the long tail of weird
   C idioms in real headers.

3. **Translate macros aggressively.** Zig translates far more macros
   than most people expect is possible. The payoff is huge — users
   rarely need to write manual bindings.

4. **Cache aggressively.** Re-parsing system headers on every build
   is too slow. Zig caches parsed results.

5. **Show untranslated items.** When something can't be translated,
   tell the user what and why. Don't silently drop it.

---

## 17. Standard Library Implementation (Phase 3)

The standard library is the primary deliverable of Phase 3. Its
quality determines whether With feels like a real language or a
research prototype. This section covers implementation strategy,
platform abstraction, and prioritization.

### 17.1 Architecture: Three Layers

```
┌──────────────────────────────────────────────────┐
│  Layer 2: std.*                                  │
│  (idiomatic With — what users import)            │
│  std.fs, std.io, std.time, std.net, etc.         │
├──────────────────────────────────────────────────┤
│  Layer 1: std.os.{posix, windows, darwin}        │
│  (thin safe wrappers around platform syscalls)   │
│  Uses c_import internally, pub(crate) only       │
├──────────────────────────────────────────────────┤
│  Layer 0: c_import (compiler built-in)           │
│  (Phase 0, already available)                    │
└──────────────────────────────────────────────────┘
```

Layer 1 is **internal** — it is not part of the public API. Users
import `std.fs.File`, never `std.os.posix.open`. This allows the
platform layer to change without breaking user code.

### 17.2 Platform Abstraction Strategy

Each `std.*` module has a single public API. Internally, it
dispatches to platform-specific implementations:

```
// std/fs/file.w (simplified)
module std.fs

comptime if cfg.target_os == "linux" or cfg.target_os == "darwin":
    use std.os.posix as platform
comptime else if cfg.target_os == "windows":
    use std.os.windows as platform

pub type File = { handle: platform.FileHandle }

pub fn open(path: &str, mode: OpenMode) -> Result[File, IoError] =
    let raw = platform.open(path.as_cstr(), mode.to_flags())?
    Ok(File { handle: raw })
```

The platform modules themselves use `c_import`:

```
// std/os/posix/fs.w (simplified)
module std.os.posix

use c_import("fcntl.h", link: "c")
use c_import("unistd.h", link: "c")

pub(crate) type FileHandle = { fd: i32 }

pub(crate) fn open(path: &CStr, flags: i32) -> Result[FileHandle, IoError] =
    let fd = unsafe { c.open(path.as_ptr(), flags) }
    if fd < 0 then
        Err(IoError.from_errno())
    else
        Ok(FileHandle { fd })
```

### 17.3 Error Type Strategy

Every `std.*` module defines its own error enum. No errno. No
integer error codes. Errors carry structured context.

```
error IoError =
    NotFound(path: String)
    PermissionDenied(path: String)
    AlreadyExists(path: String)
    ConnectionRefused(addr: SocketAddr)
    TimedOut
    BrokenPipe
    Interrupted
    Other(os_code: i32, msg: String)
```

The `Other` variant captures unexpected OS errors with the raw
error code for debugging. All standard error types implement
`Display` and `Debug`.

A top-level `std.error.AppError` can wrap any stdlib error via
the `from` conversion trait:

```
error AppError =
    Io(IoError)
    Net(NetError)
    Parse(ParseError)

impl From[IoError] for AppError {
    fn from(e: IoError) -> AppError = AppError.Io(e)
}
```

This lets `?` propagate through mixed error types naturally.

### 17.4 Implementation Priorities

Phase 3 is split into sub-phases. Each sub-phase produces a
working, testable subset:

**Phase 3a — Core (blocks everything else):**

| Module | Key types | C headers wrapped |
|--------|-----------|-------------------|
| `std.mem` | size_of, align_of, copy | `string.h`, `stdlib.h` |
| `std.fmt` | Display, Debug, format | `stdio.h` (sprintf) |
| `std.io` | Reader, Writer, print/println | `stdio.h` (fread, fwrite) |
| `std.fs` | File, read_file, write_file | `fcntl.h`, `unistd.h`, `dirent.h` |
| `std.string` | String methods, StrView methods | `string.h`, `ctype.h` |
| `std.collections` | Vec, HashMap, HashSet | none (pure With) |

After Phase 3a, users can write real programs that read files,
process strings, use collections, and print output — without ever
touching `c_import`.

**Phase 3b — Systems:**

| Module | Key types | C headers wrapped |
|--------|-----------|-------------------|
| `std.time` | Instant, Duration, SystemTime | `time.h`, `sys/time.h` |
| `std.math` | f32/f64 methods, PI, E | `math.h` |
| `std.process` | args, env, exit, Command | `stdlib.h`, `unistd.h` |
| `std.random` | Rng | `stdlib.h` (or platform-specific) |
| `std.hash` | Hasher, DefaultHasher | none (pure With) |
| `std.collections` | SlotMap, Handle, BTreeMap | none (pure With) |

**Phase 3c — Concurrency foundations:**

| Module | Key types | C headers wrapped |
|--------|-----------|-------------------|
| `std.thread` | spawn_os, JoinHandle | `pthread.h` |
| `std.sync` | Mutex, RwLock, Atomic, Condvar | `pthread.h`, `stdatomic.h` |
| `std.alloc` | Arena, Pool | `stdlib.h` (malloc, free) |

Phase 4 (fiber runtime, async/await, std.net) builds on top of 3c.

### 17.5 Pure-With vs. Wrapper Modules

Some modules are pure With code with no C dependency:

- `std.collections` (Vec, HashMap, HashSet, SlotMap, BTreeMap)
- `std.hash`
- Option/Result combinator methods

These should be implemented first since they have no platform
dependency and are testable immediately.

Wrapper modules (`std.fs`, `std.io`, `std.time`, `std.thread`,
`std.sync`) depend on `c_import` and require platform-specific
testing.

### 17.6 Scoped Integration

Standard library types should implement syntax traits (§11.7) where
natural:

| Type | Trait | Syntax unlocked |
|------|-------|-----------------|
| `File` | `Scoped` | `with File.open(path)? as f:` |
| `Mutex[T]` | `ScopedMut` | `with mutex.lock() as mut data:` |
| `RwLock[T]` | `Scoped` / `ScopedMut` | `with rwlock.read() as data:` |
| `Vec[T]` | `Iter[T]` | `for x in vec:` |
| `Vec[T]` | `Index[usize, T]` | `vec[i]` |
| `HashMap[K,V]` | `Index[K, V]` | `map[key]` |
| `String` | `Iter[char]` | `for ch in string:` |
| `Result[T,E]` | `Try[T, E]` | `result?` |
| `Option[T]` | `Try[T, Unit]` | `option?` |
| `Arena` | `Scoped` | `with arena.alloc() as block:` |

This ensures `with` blocks appear naturally whenever users interact
with resources — files, locks, arenas — reinforcing the language's
identity.

### 17.7 Testing Strategy

Every public function in the standard library must have:

1. **Unit test** — correct behavior on valid input
2. **Error test** — correct error type on invalid input
3. **Edge test** — empty strings, zero-length slices, max values
4. **Platform test** — runs on Linux, macOS, Windows

The test runner from Phase 2 is used. Tests are in companion
`*_test.w` files next to the module source.

Cross-platform CI is essential from Phase 3a onward. Every PR must
pass on all three platforms.

### 17.8 Documentation

Every public type and function in the stdlib must have doc comments.
The `with doc` tool (§18.5) generates browsable HTML documentation.

Documentation must include:

- One-line summary
- Parameter descriptions
- Return type and error conditions
- At least one usage example
- Cross-references to related functions

The standard library documentation is the language's primary
teaching material. Its quality matters more than any tutorial.

---

*The With Programming Language — End of implementation notes.*
