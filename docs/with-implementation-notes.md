# The With Programming Language — Implementation Notes

**Companion to:** Specification v6.3
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
    → comptime Evaluation (compile-time functions, comptime if/for, TypeInfo)
    → cfg Conditional Compilation (comptime if cfg.target_os, etc.)
    → Default Field Value Insertion (insert missing defaults at construction sites)
    → Type Checker (bidirectional, local inference)
    → Implicit Ok Wrapping (insert Ok(...) on Result-returning functions)
    → String Auto-Promotion (insert .to_owned() on literals in owned contexts)
    → Auto-Referencing (insert & on owned values passed to &T params)
    → Auto-Dereferencing (insert * chains for field/method access through ptrs)
    → Implicit Trait Object Coercion (insert vtable construction for &T → &dyn Trait)
    → Enum Accessor Generation (emit .is_*()/.as_*()/.as_*_ref()/.as_*_mut())
    → Chained if-let Desugaring (flatten comma-separated let bindings)
    → Ephemeral Checker (post-type-check AST walk)
    → Borrow Checker (intra-procedural, NLL)
    → Object Safety Check (validate dyn Trait usage)
    → May-Suspend Analysis (whole-program boolean propagation)
    → Suspend-Safety Check (@[no_await_guard] NLL liveness, extern callback)
    → Denied-Pattern Check (unused Task, unnecessary unsafe,
          unreachable code, implicit narrowing)
    → Lint Warnings (unused Result/@[must_use], configurable severity)
    → MIR Lowering (desugaring: with-blocks, generators, pattern matching,
          defer, select await, closures, distinct types, tuples)
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

**Default behavior (user code):** The caller does not know *which*
parameter is actually borrowed — it treats all of them conservatively.
This is less precise than Rust but eliminates lifetime annotations.

**Stdlib narrowing (spec §21.1 Rule 6):** The compiler has built-in
knowledge of standard library types (HashMap, Vec, slice iterators,
etc.) and correctly narrows the borrow to the relevant parameter. For
example, `HashMap.get(&self, key: &K) -> Option[&V]` borrows only
from `&self`, not from `key`. The stdlib achieves this via `unsafe`
internally — users never see it. The compiler encodes this knowledge
as a whitelist of stdlib function signatures with explicit borrow
provenance annotations.

**Implementation:** The borrow checker maintains a mapping from known
stdlib function signatures to their precise borrow outputs. When a
call to a known function is encountered, the borrow checker uses the
precise provenance instead of the conservative all-inputs default.

For user code, the conservative default applies. The precision loss
is small in practice. It occasionally forces a programmer to
restructure code (e.g., take one reference parameter instead of two),
but this is rare and the error messages are clear.

---

## 3. Ephemeral Type Checker

Post-type-check AST walk. No dataflow analysis required.

### 3.1 Rules

| # | Rule | Action |
|---|------|--------|
| 1 | `&T`, `&mut T`, `StrView`, `&[T]`, `&mut [T]` | Mark ephemeral |
| 2 | Type declared `ephemeral` | Mark ephemeral |
| 3 | Generic `F[T]` where `T` is ephemeral | Mark ephemeral |
| 4 | Struct with ephemeral field, not marked `ephemeral` | Reject definition |
| 5 | `let x = expr` where expr is ephemeral | Mark `x` ephemeral |
| 6 | Struct field of ephemeral type | Reject |
| 7 | Container insertion of ephemeral value | Mark container binding ephemeral |
| 8 | Function returning ephemeral | Callers inherit restriction |
| 9 | Escaping closure capturing ephemeral | Reject |
| 10 | Guarded `with` block (Form 1) result is ephemeral | Reject |
| 11 | `Task[T]` created from ephemeral captures/arguments | Mark task binding ephemeral |

Note: Rule 11 was removed from the normative rules (spec §22.1) since
Task ephemerality is now covered by Rule 5 + creation-site analysis
(see §3.3 below). The implementation-level guidance remains the same.

### 3.2 Implementation Notes

The checker walks the AST once, maintaining a set of "ephemeral"
bindings per scope. It does not need fixpoint iteration because
ephemerality is structural (determined by types, not by data flow).

Rule 7 is permissive in local scope: containers that receive ephemeral
elements (for example `Vec[TokenView]`) become ephemeral themselves,
but are still usable as locals. Reject only when they escape via
storage, return, or thread transfer.

For Rule 8: when analyzing a function call, check if the callee's
return type is ephemeral. If so, the binding receiving the result is
marked ephemeral. If the current function returns this binding, the
current function's return type must also be ephemeral (or it's an error).

Rule 10 applies only to guarded `with` form (`Scoped`/`ScopedMut`).
Binding forms (plain `let`/`var` desugaring) follow the normal rules.

For Rule 11 (`Task` ephemerality), classify at creation sites. If any
captured value is ephemeral, mark the produced task binding ephemeral.
Propagate this binding-level marker through assignment and parameter
passing exactly like other ephemeral bindings.

### 3.3 Task Ephemerality (spec §14.21)

Ephemerality for `Task[T]` is a **per-binding** property, not a
per-type property. The type `Task[i32]` is the same whether ephemeral
or storable. The compiler determines ephemerality at the creation site:

```
fn classify_task_ephemerality(call_expr):
    let args = call_expr.arguments()
    for arg in args:
        if is_ephemeral(arg):
            return EPHEMERAL    // task borrows caller's stack
    return STORABLE             // task owns all captures
```

**Ephemeral tasks require synchronous cancellation on drop:**

When an ephemeral task is dropped (goes out of scope without `.await`
or explicit `cancel`), the runtime must ensure the fiber has stopped
before the caller proceeds. This is mandatory for memory safety —
the fiber holds references to the caller's stack. See spec §14.7 for
the cancellation protocol.

**Restriction:** Ephemeral tasks can only be created inside fibers
(async contexts). Creating an ephemeral task on a bare OS thread or
in an FFI callback is a compile error — these contexts cannot yield
to the scheduler and dropping the task would deadlock.

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

// Mutable binding (builder pattern / extraction pattern)
with expr as mut name: body
// If body tail type is Unit:
// → { var name = expr; body; name }
// Else:
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

### 6.3 `async:` Block Lowering

```
let t = async: body
```

Compiles to:

```
let t = runtime::spawn_fiber(move || { body })
```

`async:` is expression-oriented sugar over the same fiber spawn path
used by `async fn`.

### 6.4 Structured Concurrency Lowering (`async scope`)

```
async scope |s|:
    body
```

Compiles to:

```
runtime::structured_scope(|s| { body })
```

`s.track(task_expr)` registers existing tasks for scope-managed
cleanup and returns a `ScopedTask[T]` — a handle that behaves like
`Task[T]` (supports `.await`, `cancel`, `is_done`) but is exempt
from `@[must_use]`. The scope guarantees cleanup: when it exits
(normally or via `?`), all tracked tasks are cancelled and joined.

### 6.5 `spawn` Lowering (Detached Fire-and-Forget)

```
spawn send_analytics("page_view")
```

Compiles to:

```
let __task = send_analytics("page_view")
runtime::detach(__task)   // returns Unit
```

`spawn` is the only fire-and-forget path that keeps the fiber alive
independently from local ownership.

### 6.6 `may_suspend` Analysis

The compiler computes a boolean `may_suspend` for every function:

1. Seed: any function containing `.await` is `may_suspend = true`.
2. Propagate through the call graph to a fixpoint (SCC-aware).
3. Mark closures and inline blocks similarly based on contained calls.

**Closure propagation:** Closures inherit `may_suspend` from their
body. A closure that calls a `may_suspend` function is itself
`may_suspend`. When a closure is passed to a higher-order function,
the higher-order function becomes `may_suspend` if it invokes the
closure. For indirect calls through `dyn Trait` or function pointers,
the compiler conservatively marks the call as `may_suspend = true`
unless the function pointer type is annotated or constrained.

**Implementation detail:** The call graph includes edges from higher-
order functions to the closures they receive. Closures passed as
direct arguments are analyzed inline. Closures stored in variables or
passed through generic type parameters require the fixpoint analysis
to converge. SCC (strongly connected component) decomposition ensures
mutual recursion between closures and functions is handled correctly.

This property feeds two mandatory checks:

- Reject calls to `may_suspend` functions while a live
  `@[no_await_guard]` value exists (NLL liveness).
- Reject `may_suspend` functions or closures in `extern "C"` callback
  positions (spec §14.18 — no suspension while C frames are on stack).

### 6.7 `no_runtime` Gate

The compiler maintains a `runtime_available` flag from build config.
In `no_runtime` builds:

- Any `async fn` declaration → compile error
- Any `async:` block → compile error
- Any `.await` expression → compile error
- `async scope` → compile error
- `spawn` → compile error

Error message:

```
ERROR: `async` requires the fiber runtime.
       Set `runtime = true` in with.toml.
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

A naive implementation allocates a fixed stack per fiber. The spec
defines 64 KB as the default maximum stack and 8 KB as the initial
allocation (growable). At scale using the max:

```
100K fibers × 64KB = 6.4GB
  1M fibers × 64KB = 64GB
```

In practice most fibers stay near the 8 KB initial allocation:

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
Stack size:     8KB default (spec §14.18: 8KB initial, 64KB max growable)
Allocation:     mmap per fiber (or pool)
100K fibers:    ~800MB (worst case; suspended fibers often < 2KB)
Overhead:       None (no prologue checks)
Complexity:     Minimal
```

Note: the spec (§14.18) defines 64 KB as the default maximum stack and
8 KB as the initial allocation. The `with.toml` runtime section
(`fiber_stack_size`, `fiber_initial_stack`, `fiber_pool_size`)
configures these values. For a fixed-stack prototype, 8 KB is a
reasonable starting point. The v1.0 phasing table targets segmented
stacks with 8 KB initial (see §8.3).

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

Guard suspension safety is a separate pass: combine NLL liveness
(`@[no_await_guard]` values live at point P) with `may_suspend`
call metadata to reject illegal suspension edges.

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
drop(p1.x)            // drop each overwritten field!
let p2 = Point { x: 3.0, y: p2_y }
// p1 is now fully consumed — no leak, no double-free
```

**Critical:** The compiler must emit `drop` calls for overwritten
fields. Without this, `p1.x` (if it were heap-allocated) would
leak — it was never moved to `p2` and never explicitly dropped.

The compiler must track partial moves through record update syntax.

### 10.1 Drop Types and Record Update

**Partial moves from Drop types are forbidden** (spec §2.4). If the
base expression's type implements `Drop`, record update syntax is a
compile error:

```
type FileWrapper = { fd: File, name: String }
impl Drop for FileWrapper
    fn drop(self: Self) = close_file(self.fd)

let w1 = FileWrapper { fd: open_file(), name: "A" }
let w2 = { w1 with name: "B" }   // ERROR: partial move from Drop type
```

**Rationale:** A partial move would leave the base in a partially-
valid state. If its destructor were then called, it would access
moved-out fields. By-value `drop(self: Self)` prevents defensive
null checks — the value is consumed whole.

**Implementation:** At record update sites, check `typeof(base)` for
`Drop` implementation. If found, emit error E0XXX pointing at the
base expression and suggesting `.clone()` or restructuring.

For non-Drop types, the partial-move + drop-overwritten-fields
lowering described above applies.

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
| Tuple | Anonymous C struct (field0, field1, ...) |
| Distinct type | Wrapper struct around base type |
| Function | C function |
| Closure (non-escaping) | Inlined at call site (no allocation) |
| Closure (escaping) | Struct (captured vars) + function pointer |
| Generic | Separate C function per monomorphization |
| `dyn Trait` | Fat pointer (data ptr + vtable ptr) |
| Move | memcpy + null source (debug) |
| Drop | Call destructor function before scope exit |
| `defer` | Emitted as cleanup code before every scope exit path |
| Borrow check | Erased (compile-time only) |
| Ephemeral check | Erased (compile-time only) |
| `@[no_await_guard]` | Erased (compile-time only) |
| `comptime` | Evaluated during compilation; result embedded as constant |
| String literal | Static `const char[]` + length |
| `async fn` | Function returning Task handle; fiber spawned via runtime |
| `gen fn` | State struct + `next()` function |
| `select await` | Dispatch table + cancellation of losers |
| Channel | Ring buffer + fiber wait queues |
| `@[repr(C)]` | C struct with platform ABI layout |

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

**`may_suspend` call while `@[no_await_guard]` is live:**
```
error[E0701]: may_suspend call while `@[no_await_guard]` guard is live
  --> src/service.w:15:9
   |
14 |     with self.cache.lock() as data:
   |          ------------------- MutexGuard is @[no_await_guard]
15 |         helper(data.url)
   |         ^^^^^^^^^^^^^^^^ helper may suspend (directly or transitively)
   |
   = help: call helper after guard drop, or refactor helper to be non-suspending
```

**Unused Result:**
```
warning[W0802]: unused `Result` — error may be silently swallowed
  --> src/main.w:8:5
   |
 8 |     db.execute("DROP TABLE users")
   |     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Result[Unit, DbError] unused
   |
   = help: propagate with `?`, handle with match, or discard with
           `let _ = ...`
   = note: promote to error with `must_use = "error"` in with.toml
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
   = help: use `.await` to wait for completion
   = help: use `cancel(task)` for explicit cancellation
   = help: use `spawn ...` for fire-and-forget
   = note: `let _ = ...` on a Task cancels immediately and should emit a warning
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

### 15.3 Denied Patterns Diagnostics (spec §20b)

These are compile errors, not warnings. The compiler must enforce
all of the following unconditionally:

| Pattern | Code | Spec ref | Severity |
|---------|------|----------|----------|
| `.await` while `@[no_await_guard]` is live | E0701 | §20b.1 | Error |
| `may_suspend` call while guard is live | E0701 | §20b.1 | Error |
| Unused `Result` value | W0802 | §20b.2 | Warning (configurable) |
| Unused `Task` value | E0801 | §20b.3 | Error |
| Unnecessary `unsafe` block | E0901 | §20b.4 | Error |
| Implicit numeric narrowing | E0201 | §20b.5 | Error |
| Unreachable code | E0601 | §20b.6 | Error |

Unused `Result` is a warning by default. Projects can promote it to
an error via `with.toml`:

```toml
[lint]
must_use = "error"
```

**Implementation order:** The denied-pattern checks run as a
late pass after borrow checking and may-suspend analysis, since
some checks (like E0701) depend on NLL liveness and may-suspend
data. The unreachable code check (E0601) runs after comptime
evaluation — branches eliminated by `comptime if` are erased
before the check.

**`let _ = task` warning:** Per spec §20b.3, `let _ = ...` on a
Task cancels immediately and should emit a warning (not error)
suggesting `spawn` for fire-and-forget or `.await` for completion.

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
  Available as normal With symbols (direct call; no per-call `unsafe`)
```

`c_import` is the explicit safety opt-in. Imported C functions are
callable directly. `unsafe` remains required for raw pointer
operations (`*p`, pointer arithmetic, transmutes). For manually
declared `extern "C"` symbols (outside `c_import`), keep the
call-site `unsafe` requirement.

### 16.2 C Preprocessor Invocation

The compiler invokes the system C compiler in preprocessing mode:

```
cc -E \
   -I /usr/include \
   -I /usr/local/include \
   ${user_include_paths} \
   ${user_defines} \
   input_header.h \
   > preprocessed.c

cc -E -dM \
   -I /usr/include \
   -I /usr/local/include \
   ${user_include_paths} \
   ${user_defines} \
   input_header.h \
   > macros.txt
```

`-E` produces preprocessed declarations. `-dM` is run as a second
pass to dump `#define` constants.

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
| `void*` | `*mut c_void` |
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
| `#define F(a,b) expr` | Phase 0: warning + skip (manual wrapper/shim) |
| Complex macros | Warning + skip |

Phase 0 translates constant-like macros only. Function-like macro
translation is intentionally deferred because token-level C macro
semantics are not represented in the declaration AST. The compiler
should emit a warning list of untranslated macros so users can add
manual wrappers where needed.

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

3. **Translate constant macros aggressively in Phase 0.** This
   captures most practical constants (`SQLITE_OK`, `O_RDONLY`,
   `PATH_MAX`). Function-like macros can be phased in later.

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

**Phase 3d — Utilities:**

| Module | Key types | C headers wrapped |
|--------|-----------|-------------------|
| `std.signal` | Signal enum, on_signal handler | `signal.h` |
| `std.random` | Rng, seedable | `stdlib.h` or platform-specific |

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

### 17.7 Additional Standard Library Requirements

**`Shared[T]` convenience type (spec §8.4):**

```
type Shared[T] = Arc[RwLock[T]]
```

Must implement `Scoped[T]` and `ScopedMut[T]` for `with` blocks.
This is the recommended type for shared mutable state across threads
and fibers when full ownership semantics are not needed.

**Prelude `drop` function (spec §18.2):**

```
fn drop[T](val: T) = ()
```

A built-in identity function that takes any value by move and does
nothing — the value is destroyed when the argument goes out of scope.
Must be in the prelude. Primary use: explicitly trigger resource
cleanup (e.g., `drop(tx)` to close a channel sender).

**Collection `.len32()` / `.len64()` methods (spec §18.6):**

All collection types provide convenience narrowing methods:

| Method | Return | Behavior |
|--------|--------|----------|
| `.len()` | `usize` | Length (always available) |
| `.len32()` | `i32` | Panics if len > `i32.max` |
| `.len64()` | `i64` | Panics if len > `i64.max` |
| `.ulen32()` | `u32` | Panics if len > `u32.max` |

These avoid the ubiquitous `.len() as i32` cast pattern.

**`c_errno` compiler intrinsic (spec §18.6 "The errno Principle"):**

The standard library reads C `errno` via `std.os.c_errno()`, which
the compiler lowers to the platform-appropriate thread-local access
(e.g., `(*__errno_location())` on glibc). This is NOT a `c_import`
translation — `errno` on glibc is a complex macro. The compiler
provides this as a built-in intrinsic.

### 17.8 Testing Strategy

Every public function in the standard library must have:

1. **Unit test** — correct behavior on valid input
2. **Error test** — correct error type on invalid input
3. **Edge test** — empty strings, zero-length slices, max values
4. **Platform test** — runs on Linux, macOS, Windows

The test runner from Phase 2 is used. Tests are in companion
`*_test.w` files next to the module source.

Cross-platform CI is essential from Phase 3a onward. Every PR must
pass on all three platforms.

### 17.9 Documentation

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

## 18. Default Field Values Compilation (spec §4.3)

Default field values are a **comptime transformation**. The compiler
inserts the default expressions for missing fields at each
construction site.

### 18.1 Algorithm

```
fn lower_struct_construction(site, type_def):
    let provided_fields = site.explicit_fields()
    for field in type_def.fields:
        if field.name not in provided_fields:
            if field.has_default:
                // Insert default expression at construction site
                site.add_field(field.name, field.default_expr.clone())
            else:
                EMIT ERROR "missing field `{field.name}` with no default"
```

### 18.2 Key Properties

- Default expressions are **evaluated at the construction site**, not
  at type definition time. Each construction gets a fresh evaluation.
- Default expressions must be valid at any construction site (no
  capturing locals from the definition scope).
- Defaults compose with field shorthand and record update syntax.
- The compiler clones the AST of the default expression into each
  missing-field site, then type-checks as normal.

### 18.3 Interaction with Record Update

Record update `{ base with field: val }` only overrides explicitly
named fields. Fields not mentioned in the override are taken from
`base`, not from defaults. Default values apply only to fresh
construction sites (no base expression).

---

## 19. Enum Accessor Method Generation (spec §4.4)

Every enum variant with data automatically generates `.is_variant()`,
`.as_variant()`, `.as_variant_ref()`, and `.as_variant_mut()` methods.
This is unconditional — no `@[derive]` needed.

### 19.1 Generation Rules

```
fn generate_accessors(enum_def):
    for variant in enum_def.variants:
        let snake_name = to_snake_case(variant.name)

        // .is_variant() → bool (always generated)
        emit fn is_{snake_name}(self: &EnumType) -> bool =
            match self
                EnumType.{variant.name}(..) -> true
                _ -> false

        // .as_variant() → Option[T] (only for data variants)
        if variant.has_data:
            let T = if variant.fields.len() == 1:
                variant.fields[0].type
            else:
                tuple(variant.fields.types)

            // By value (moves)
            emit fn as_{snake_name}(self: EnumType) -> Option[T] =
                match self
                    EnumType.{variant.name}(val) -> Some(val)
                    _ -> None

            // By shared reference
            emit fn as_{snake_name}_ref(self: &EnumType) -> Option[&T] =
                match self
                    EnumType.{variant.name}(ref val) -> Some(val)
                    _ -> None

            // By mutable reference
            emit fn as_{snake_name}_mut(self: &mut EnumType) -> Option[&mut T] =
                match self
                    EnumType.{variant.name}(ref mut val) -> Some(val)
                    _ -> None
```

### 19.2 Key Properties

- Method names use `snake_case` conversion of variant names.
- `.as_variant()` takes `self` by value (consumes the enum).
- `.as_variant_ref()` takes `self: &Self` (shared borrow).
- `.as_variant_mut()` takes `self: &mut Self` (mutable borrow).
- Multi-field variants: all three forms return tuple types.
- Unit variants (no data) only generate `.is_variant()`.
- The `_ref` variants are essential for navigating tree structures
  (ASTs, JSON, nested enums) without cloning.
- These methods are emitted early in the pipeline and go through
  normal type checking.

---

## 20. Tuple Compilation (spec §4.8)

### 20.1 Representation

Tuples compile to anonymous C structs:

```
// (i32, str, bool) →
struct __tuple_i32_String_bool {
    i32 field0;
    String field1;
    bool field2;
};
```

### 20.2 Key Properties

- Index access (`pair.0`, `pair.1`) compiles to struct field access.
- Destructuring compiles to multiple field reads.
- A tuple is `Copy` if all elements are `Copy`.
- A tuple is ephemeral if any element is ephemeral.
- Tuples participate in monomorphization — each distinct element type
  combination produces a separate struct.
- The unit type `Unit` is equivalent to the empty tuple `()`.

### 20.3 Unit Elision (spec §4.8)

When a function expects a single `Unit` argument and the call site
omits it, the compiler inserts `()`:

```
unwrap_or()  →  unwrap_or(())
Some()       →  Some(())
Ok()         →  Ok(())
```

Unit elision applies **only when the expected parameter type is
statically known to be `Unit`** via bidirectional type inference.
It does NOT apply to unconstrained generics.

---

## 21. Implicit `Ok` Wrapping (spec §4.9)

### 21.1 Algorithm

When a function's declared return type is `Result[T, E]`:

1. If the last expression in the body has type `T` (not `Result`),
   wrap it in `Ok(...)`.
2. If the return type is `Result[Unit, E]` and the block ends with
   a statement (no trailing expression), insert `Ok(())`.
3. If the last expression already has type `Result[T, E]`, no
   wrapping occurs.

### 21.2 Implementation

This is a post-type-check desugaring. After inferring the body's
type and comparing it to the declared return type:

```
fn check_implicit_ok(func):
    let ret_type = func.declared_return_type
    if not is_result_type(ret_type):
        return  // not applicable

    let Result(T, E) = ret_type
    let body_type = typeof(func.body)

    if body_type == T:
        // Wrap in Ok
        func.body = Ok(func.body)
    else if T == Unit and func.body.is_statement_terminated():
        // Insert Ok(()) at end
        func.body.append(Ok(()))
    else if body_type == ret_type:
        // Already Result — no wrapping
        pass
    else:
        EMIT TYPE ERROR
```

---

## 22. `defer` Compilation (spec §2.4)

### 22.1 Lowering

`defer` statements are lowered by duplicating the deferred code at
every scope-exit point:

```
fn process(path: str) -> Result[Unit, IoError] =
    let f = fs.open(path)?
    defer f.close()
    f.write_all(b"data")?
    // f.close() runs here
```

Compiles to:

```
fn process(path: str) -> Result[Unit, IoError] =
    let f = match fs.open(path) {
        Ok(v) -> v
        Err(e) -> return Err(e.into())  // no defer yet
    }
    match f.write_all(b"data") {
        Ok(v) -> v
        Err(e) -> { f.close(); return Err(e.into()) }
    }
    f.close()
    Ok(())
```

### 22.2 Key Rules

- `defer` statements execute in LIFO (reverse declaration) order.
- `return`, `break`, `continue`, and `?` are **compile errors**
  inside `defer` blocks.
- Multiple `defer` in the same scope: each scope-exit path runs
  all active defers in reverse order.
- Tail call optimization: a call in `defer` scope breaks tail
  position (the defer must run after the call).

### 22.3 Implementation Strategy

Option A (code duplication): Clone the defer body at every exit
point. Simple but increases code size with many defers.

Option B (cleanup labels): Emit a cleanup block at the end of the
scope; each exit path jumps to the cleanup label. This is what LLVM
and GCC do for C++ destructors. Recommended for v1.0.

---

## 23. `select await` Compilation (spec §14.10)

### 23.1 Desugaring

```
select await
    msg = rx.recv() -> handle(msg)
    _ = timeout(1.secs()) -> println("timeout")
```

Compiles to:

```
// 1. Start all expressions as concurrent tasks
let __branch0 = rx.recv()         // returns Task
let __branch1 = timeout(1.secs()) // returns Task

// 2. Race: suspend until any completes
let (winner, result) = runtime::select([__branch0, __branch1])

// 3. Cancel losers
for task in [__branch0, __branch1] if task != winner:
    cancel(task)

// 4. Dispatch to winner's body
match winner
    0 -> { let msg = result as T0; handle(msg) }
    1 -> { let _ = result as T1; println("timeout") }
```

### 23.2 Fair vs Biased Selection

**Fair (default):** When multiple branches are simultaneously ready,
select a ready branch at pseudo-random (prevent starvation).

**Biased (`select await biased`):** Select the first textual branch
that is ready (top-to-bottom priority). Used when deterministic
priority ordering is needed.

### 23.3 Implementation

The runtime `select` primitive:

1. Registers interest in all provided tasks.
2. If any are already complete, returns immediately (fair: random
   pick among completed; biased: first completed in order).
3. Otherwise, suspends the calling fiber with a multi-wait entry
   that is woken by any of the registered tasks.
4. On wake, cancels all non-completed tasks and returns the winner.

### 23.4 Composing with Loops

`select await` inside a `loop:` is the idiomatic event loop pattern.
The compiler must ensure cancelled tasks from previous iterations are
properly cleaned up before starting new ones.

---

## 24. Channel Implementation (spec §14.14)

### 24.1 Architecture

```
type Channel[T] = {
    buffer:    RingBuffer[T],   // bounded buffer
    senders:   WaitQueue,       // fibers blocked on send
    receivers: WaitQueue,       // fibers blocked on recv
    closed:    AtomicBool,
}
```

### 24.2 Key Properties

- Channels transfer ownership: sending moves the value.
- Channel element types must be `Send` (not merely `ScopedSend`).
  This is critical — channels decouple sender and receiver lifetimes.
- `tx.send(msg).await` suspends the fiber if the buffer is full.
- `rx.recv().await` suspends the fiber if the buffer is empty.
- `try_recv()` is non-blocking (returns `Option`).
- Dropping all senders closes the channel; receivers see `None`.

### 24.3 Fiber-Aware Blocking

Channel operations yield to the fiber scheduler, not the OS thread:

```
fn send(self: &Channel[T], val: T) -> Task[Unit]:
    if self.buffer.try_push(val):
        wake_one(self.receivers)
        return // immediate completion
    // Buffer full — suspend fiber
    self.senders.enqueue(current_fiber, val)
    yield_to_scheduler()
```

---

## 25. `ScopedSend` Trait Implementation (spec §14.15)

### 25.1 Trait Hierarchy

```
Send       ⊂ ScopedSend     (all Send types are ScopedSend)
Ephemeral  ⊂ ScopedSend     (ephemeral types are ScopedSend)
Rc[T]      ∉ ScopedSend     (not thread-safe at all)
```

### 25.2 Auto-Implementation

`ScopedSend` is automatically derived:

- All `Send` types implement `ScopedSend`.
- Ephemeral types (`&T`, `&mut T`, ephemeral structs) implement
  `ScopedSend` but NOT `Send`.
- `Rc[T]` implements neither `Send` nor `ScopedSend`.

### 25.3 Where Each Trait Is Required

| Context | Required trait |
|---------|---------------|
| `thread.spawn_os(closure)` | All captures must be `Send` |
| `scope \|s\|: s.spawn(closure)` | All captures must be `ScopedSend` |
| `async scope \|s\|: s.track(task)` | All task captures must be `ScopedSend` |
| Channel `tx.send(val)` | Value must be `Send` |

### 25.4 Implementation

The compiler auto-derives `Send` and `ScopedSend` based on field
types, similar to how `Copy` is derived. No explicit `impl Send`
is needed for most types. `unsafe impl Send` is available for types
that contain raw pointers but are known to be thread-safe.

---

## 26. `comptime` Metaprogramming Implementation (spec §17)

### 26.1 Architecture

The compiler includes a comptime evaluator — an interpreter that
executes With code at compile time. It runs after name resolution
and before type checking (for `comptime if cfg.*`) or during
monomorphization (for `comptime if TypeInfo.*`).

### 26.2 Evaluator Capabilities

The comptime evaluator can:

- Execute pure functions (no I/O, no heap persistence to runtime)
- Access `TypeInfo` API (fields, variants, size, align, name, traits)
- Iterate over types with `comptime for`
- Branch on types with `comptime if`
- Generate trait implementations via `@[derive]`
- Produce compile errors via `comptime_error("message")`

### 26.3 `TypeInfo` / Type Method Implementation

Type introspection is available via two syntaxes:

- `T.fields()`, `T.name()`, `T.size()`, etc. — method syntax on type
  parameters inside comptime context (preferred)
- `TypeInfo.fields[SomeType]()` — module syntax for concrete types

Both are compiler intrinsics lowered to constant lookups into the
type metadata tables built during type checking.

```
T.fields()              // → [FieldInfo]
T.variants()            // → [VariantInfo]
T.size()                // → usize
T.align()               // → usize
T.name()                // → str
T.implements(Trait)      // → bool
T.is_copy()             // → bool
```

### 26.4 `comptime for` Unrolling and Cascade

**Comptime cascade:** Inside a `comptime fn` or `comptime for`, all
code is already executing at compile time. Inner `for`, `if`, and
other statements do NOT need the `comptime` prefix — it cascades
automatically. The `comptime` prefix is only needed at the entry
point.

```
comptime fn derive_serialize[T: type]() =
    for field in T.fields():           // cascade: no prefix needed
        if field.type_name == "str":   // cascade: no prefix needed
            emit_string_serialize(field)
        else:
            emit_generic_serialize(field)
```

`comptime for` unrolls at compile time. The loop body is stamped out
once per iteration with compile-time constants substituted.
`self.{field.name}` is a comptime field access — the compiler
resolves the field name from the constant string and emits a direct
field access.

### 26.5 Deferred Branch Checking

For `comptime if` inside generic functions that depend on type
parameter `T`:

1. Non-comptime code is type-checked against declared bounds on `T`.
2. Code inside `comptime if` branches depending on `T` is deferred.
3. At monomorphization, the branch condition is evaluated.
4. The taken branch is type-checked against concrete `T`.
5. The eliminated branch is discarded without checking.

This is narrower than C++ templates (non-comptime body is still
checked) and broader than Rust generics (comptime branches can use
capabilities not in bounds).

### 26.6 `@[derive]` Integration

`@[derive(TraitName)]` is sugar for invoking a comptime function:

```
@[derive(Serialize)]
type User = { name: String, age: i32 }

// Equivalent to:
comptime derive_serialize[User]()
```

The compiler looks up `derive_serialize` (or the built-in handler
for structural traits like `Eq`, `Hash`, `Clone`, `Copy`, `Debug`)
and invokes it at compile time. The generated `impl` block goes
through normal type checking.

---

## 27. Closure Compilation (spec §12)

### 27.1 Classification

The compiler classifies closures at definition sites:

| Context | Classification |
|---------|---------------|
| Direct argument to function call | Non-escaping |
| Bound to named variable | Escaping |
| Stored in container | Escaping |
| Returned from function | Escaping |
| Stored in struct field | Escaping |
| `with` block body (guarded form) | Non-escaping |

### 27.2 Non-Escaping Closure Lowering

Non-escaping closures are inlined at the call site. No heap
allocation. The captured variables are accessed directly from the
enclosing scope's stack frame.

```
items.for_each(|x| println(x))
// → for x in items: println(x)  (effectively)
```

Non-escaping closures may capture ephemeral values.

### 27.3 Escaping Closure Lowering

Escaping closures compile to a struct (captured variables) plus
a function pointer:

```
let offset = 5
let f = |x| x + offset

// →
struct __closure_1 { offset: i32 }
fn __closure_1_call(self: &__closure_1, x: i32) -> i32 =
    x + self.offset
let f = __closure_1 { offset: 5 }
```

Escaping closures may NOT capture ephemeral values. The compiler
enforces this as part of the ephemeral checker (Rule 9).

### 27.4 Disjoint Capture

Closures capture only the specific fields they access, not the
enclosing struct as a whole (spec §3.6). This is critical for
parallel code:

```
scope |s|:
    s.spawn(|| use(&world.positions))    // captures world.positions
    s.spawn(|| use(&mut world.velocities)) // captures world.velocities
// No conflict — disjoint captures
```

Implementation: walk the closure body, collect all accessed field
paths, and capture at the finest granularity possible.

---

## 28. Distinct Type Compilation (spec §4.5)

### 28.1 Representation

```
type UserId = distinct i64
type Meters = distinct f64
```

Distinct types are zero-cost wrappers. They compile to the same
representation as their base type — no runtime overhead.

### 28.2 Lowering

```
type UserId = distinct i64
// →
struct UserId { __value: i64 };
```

The compiler prevents implicit conversion between `UserId` and `i64`.
Explicit conversion requires `as`:

```
let id = UserId(42)     // construction
let raw = id as i64     // explicit unwrap
```

Distinct types do NOT inherit traits from their base type. The
programmer must explicitly implement or derive traits.

---

## 29. String Auto-Promotion (spec §15.3)

### 29.1 Algorithm

When the compiler encounters a string literal `"hello"` and the
expected type from context is owned `str` (not `&str`), it inserts
`.to_owned()`:

```
fn promote_string_literal(literal, expected_type):
    if expected_type == str and typeof(literal) == &str:
        return literal.to_owned()    // insert allocation
    return literal                    // no change
```

### 29.2 Contexts That Trigger Promotion

- Struct field initialization where the field type is `str`
- Function argument where the parameter type is `str`
- Variable binding with explicit type annotation `let x: str = "..."`
- Return expression where the function return type is `str`

### 29.3 Contexts That Do NOT Trigger Promotion

- Bare `let s = "hello"` with no type annotation → stays `&str`
- Function argument where the parameter type is `&str` → no promotion
- Any context where `&str` satisfies the expected type

### 29.4 Interpolated Strings

`"hello {name}"` always produces owned `str` because it must
allocate to build the result. No auto-promotion logic is needed —
the interpolation itself produces an owned string.

### 29.5 C-String Literals

`c"hello"` produces `&CStr` — a compile-time reference to a
NUL-terminated string in static memory. The compiler appends the
NUL byte automatically. `c"..."` does not support interpolation.

---

## 30. Object Safety Checking (spec §11.3)

### 30.1 Rules

A trait can be used as `dyn Trait` only if all methods are
object-safe:

| Method form | Object-safe? |
|-------------|-------------|
| `self: &Self` | Yes |
| `self: &mut Self` | Yes |
| `self: Self` (by value) | No (excluded from vtable) |
| Generic method (non-Self) | No |

### 30.2 `Box[dyn Trait]` Exception

By-value `self` methods can be called through `Box[dyn Trait]`.
The compiler generates a shim that moves the value out of the box:

```
// For trait Builder with fn build(self: Self) -> Config:
fn __box_dyn_build_shim(box_ptr: *mut u8) -> Config =
    let builder = move_from_box(box_ptr)
    builder.build()
```

### 30.3 Implementation

At trait-object creation sites (`&dyn Trait`, `Box[dyn Trait]`):

1. Check all methods of the trait for object safety.
2. If any non-object-safe method exists, emit error.
3. Build vtable with function pointers to monomorphized methods.
4. For `Box[dyn Trait]`, generate shims for by-value self methods.

---

## 31. FFI Stack Switching (spec §14.18)

### 31.1 The Problem

C code called via `c_import` has no knowledge of With's segmented/
small fiber stacks. It may use more stack space than available on the
fiber's stack.

### 31.2 Solution: Automatic Stack Switching

1. The compiler marks functions as `ffi_reachable` if they (directly
   or transitively) call any `c_import` function.
2. At the FFI call boundary, the runtime:
   a. Saves the fiber stack pointer
   b. Switches to a pre-allocated OS-thread stack (2–8 MB)
   c. Executes the C function on the full-size stack
   d. Restores the fiber stack pointer on return

Cost: ~10–50 ns per switch (save/restore a few registers).

### 31.3 `@[ffi_stack]` Attribute

For functions that call C frequently, `@[ffi_stack]` forces the
entire function to run on an OS-thread stack, avoiding per-call
switching:

```
@[ffi_stack]
fn process_image(data: &[u8]) -> Image =
    // All C calls run on OS stack without per-call switching
    ...
```

### 31.4 No Suspension During C Frames

The compiler enforces that any function used as an `extern "C"`
callback, or transitively called while C frames are on the stack,
must not be `may_suspend`. This prevents corrupting the OS-thread
stack that may be shared with paused C frames.

---

## 32. Attribute System

### 32.1 Built-In Attributes

| Attribute | Applies to | Effect |
|-----------|-----------|--------|
| `@[tailrec]` | Functions | Verify tail recursion; compile to loop |
| `@[no_await_guard]` | Types | Reject `.await`/`may_suspend` while live |
| `@[must_use]` | Types | Warn/error on unused values |
| `@[derive(...)]` | Types | Generate trait implementations (incl. Builder) |
| `@[repr(C)]` | Types | C-compatible memory layout |
| `@[c_export("name")]` | Functions | Export with C linkage |
| `@[ffi_stack]` | Functions | Run on OS-thread stack |
| `@[inline]` | Functions | Hint: inline this function |
| `@[cold]` | Functions | Hint: unlikely to be called |

### 32.2 `@[no_await_guard]` Algorithm (spec §7.9, §14.3)

This is the most complex attribute. The check combines NLL liveness
with `may_suspend` analysis:

```
fn check_no_await_guard(func):
    let guard_bindings = find_bindings_of_no_await_guard_types(func)
    let may_suspend_calls = find_may_suspend_call_sites(func)

    for call in may_suspend_calls:
        for guard in guard_bindings:
            if nll_is_live(guard, call.program_point):
                EMIT ERROR E0701
                    "may_suspend call while @[no_await_guard] guard is live"
                    point_at(guard.creation_site)
                    point_at(call.site)
                    suggest("drop guard before calling, or clone data out")
```

**Key insight:** The check is NLL-based, not syntax-based. It rejects
suspension regardless of whether the guard was created via `with` or
via a plain `let` binding. Any `may_suspend` function call (not just
direct `.await`) while a guard is live is an error.

### 32.3 `cfg` Conditional Compilation

`comptime if cfg.target_os == "linux"` is the conditional compilation
mechanism. Available `cfg` fields:

| Field | Type | Example |
|-------|------|---------|
| `cfg.target_os` | `str` | `"linux"`, `"darwin"`, `"windows"` |
| `cfg.target_arch` | `str` | `"x86_64"`, `"aarch64"` |
| `cfg.is_debug` | `bool` | `true` in debug builds |
| `cfg.is_release` | `bool` | `true` in release builds |

The `cfg` object is a comptime constant populated from the build
target and `with.toml` configuration.

---

## 33. Extension Block Coherence (spec §11.4)

### 33.1 Rules

- You may `extend` any type with new methods.
- If two packages extend the same type with the same method name,
  calling that method is a compile error (ambiguous).
- Extension methods **never shadow** inherent methods.
- Extension methods are resolved by import scope.

### 33.2 Implementation

At method resolution, the compiler:

1. Check inherent methods (same module as type). If found, use it.
2. Collect extension methods from all `use`d packages.
3. If exactly one match, use it.
4. If multiple matches, emit ambiguity error with fully-qualified
   suggestion.
5. If no match, emit "method not found" error.

---

## 34. Normative Rule §21.7: Implicit Drop as Use

### 34.1 Rule

When a variable implementing `Drop` goes out of scope, its implicit
destructor call is treated as a **use** of that variable for borrow-
checking purposes (spec §21.1 Rule 7).

### 34.2 Implementation

The compiler inserts implicit drop points at scope exit in reverse
declaration order. Each drop point extends the NLL liveness of the
variable being dropped:

```
fn example():
    var v: Vec[&i32] = Vec.new()
    var x = 5
    v.push(&x)
    // End of scope: x drops first (no Drop impl), then v drops.
    // v.drop() would access &x, but x no longer exists.
    // Rejected: v's implicit drop is a use of &x.
```

For the borrow checker, insert a virtual "use" of `v` at the point
where `v.drop()` would execute. This extends the borrow `&x` through
the destructor, causing a conflict with `x`'s destruction.

---

## 35. Auto-Dereferencing (spec §3.7)

### 35.1 Algorithm

At every field access `expr.field` and method call `expr.method()`,
the compiler tries to resolve the field/method. If it fails, it
inserts a dereference and retries:

```
fn resolve_field_access(expr, field_name):
    let ty = typeof(expr)
    loop:
        if ty has field field_name:
            return deref_chain + field_access
        if ty implements Deref:
            deref_chain.push(Deref)
            ty = ty.Deref.Target
            continue
        EMIT ERROR "no field {field_name} on {ty}"
```

Works through `&T`, `&mut T`, `Box[T]`, `Arc[T]`, `Rc[T]`, and
any user type implementing `Deref`. The compiler inserts as many
dereferences as needed.

---

## 36. Auto-Referencing (spec §3.8)

### 36.1 Rules

When a function expects `&T` and receives an owned `T`:

1. Insert `&` automatically for shared borrows.
2. Do NOT auto-ref for `&mut T` — mutation must be explicit.

```
fn check_auto_ref(arg_expr, param_type):
    let arg_type = typeof(arg_expr)
    if param_type == &T and arg_type == T:
        return &arg_expr     // insert shared borrow
    if param_type == &mut T and arg_type == T:
        EMIT ERROR           // no auto-ref for &mut
```

### 36.2 Method Calls

For method calls, auto-ref applies to the receiver. If `greet`
takes `self: &Self`, calling `alice.greet()` inserts `(&alice).greet()`.
This already happens for method receivers in most languages (Rust does
this too).

---

## 37. Implicit Trait Object Coercion (spec §3.9)

### 37.1 Algorithm

When a function expects `&dyn Trait` and receives `&T` where `T`
implements the trait:

1. Check that `T` implements `Trait` (and trait is object-safe).
2. Construct the fat pointer: `(data_ptr, vtable_ptr)`.

```
fn check_trait_coercion(arg_expr, param_type):
    if param_type == &dyn Trait:
        let arg_type = typeof(arg_expr)
        if arg_type == &T and T implements Trait:
            return make_fat_ptr(arg_expr, vtable_for(T, Trait))
```

Same logic applies for `Box[T]` → `Box[dyn Trait]`.

---

## 38. Chained `if let` Compilation (spec §9.7)

### 38.1 Desugaring

Chained `if let` with commas desugars to nested `if let`:

```
if let Some(a) = x, let Some(b) = y, a > 0:
    body
else:
    fallback

// → desugars to:
if let Some(a) = x:
    if let Some(b) = y:
        if a > 0:
            body
        else:
            fallback
    else:
        fallback
else:
    fallback
```

The `else` branch (if present) is shared across all failure paths.
Boolean conditions in the chain desugar to normal `if` checks.

### 38.2 Key Properties

- Each binding in the chain is in scope for subsequent bindings
  and the body.
- If any binding fails, the `else` branch runs (or the `if` is
  skipped if there's no `else`).
- Mixes of `let` bindings and boolean conditions are supported.

---

## 39. `@[derive(Builder)]` Implementation (spec §11.8)

### 39.1 Generated Code

For a type with `@[derive(Builder)]`:

```
@[derive(Builder)]
type Config = { host: str, port: i32 = 8080 }
```

The comptime function generates:

1. A builder struct with `Option` wrappers for each field:
   ```
   type ConfigBuilder = { host: Option[str], port: Option[i32] }
   ```

2. Chaining setter methods (by-value self):
   ```
   impl ConfigBuilder
       fn host(self: Self, val: str) -> Self =
           Self { host: Some(val), ..self }
       fn port(self: Self, val: i32) -> Self =
           Self { port: Some(val), ..self }
   ```

3. A `.build()` method that checks required fields:
   ```
   fn build(self: Self) -> Result[Config, BuilderError] =
       Config {
           host: self.host ?? return Err(.MissingField("host")),
           port: self.port ?? 8080,   // use default
       }
   ```

4. A static `.builder()` constructor on the original type.

### 39.2 Required vs Optional Fields

Fields with default values in the type definition are optional in the
builder. Fields without defaults are required — `.build()` returns
`Err(.MissingField(name))` if they aren't set.

---

## 40. HashMap Convenience Methods (spec §13.3)

### 40.1 Implementation

These are stdlib methods, not compiler features:

```
impl HashMap[K, V]
    fn update(self: &mut Self, key: K, default: V, f: fn(V) -> V) =
        let entry = self.entry(key).or_insert(default)
        *entry = f(*entry)

    fn increment(self: &mut Self, key: K) where V: Add[V, Output=V] + From[i32] =
        self.update(key, V.from(0), |n| n + V.from(1))

    fn decrement(self: &mut Self, key: K) where V: Sub[V, Output=V] + From[i32] =
        self.update(key, V.from(0), |n| n - V.from(1))

    fn append[Item](self: &mut Self, key: K, val: Item) where V: Push[Item] + Default =
        self.entry(key).or_insert(V.default()).push(val)
```

---

## 41. Raw Pointer `.as_option()` (spec §16.1)

### 41.1 Implementation

Built-in methods on raw pointer types:

```
impl *const T
    fn as_option(self: Self) -> Option[*const T] =
        if self == null then None else Some(self)

impl *mut T
    fn as_option(self: Self) -> Option[*mut T] =
        if self == null then None else Some(self)
```

These are safe — they check for null without dereferencing. The
resulting `Option[*T]` still requires `unsafe` to dereference.

---

## 42. Task Cancellation as Unwinding (spec §14.7)

### 42.1 Mechanism

Task cancellation uses structured unwinding, similar to panics but
catchable at `async scope` boundaries:

1. Cancellation flag is set on the fiber.
2. At next `await`, instead of suspending, begin unwinding.
3. Destructors run during unwinding (guaranteed).
4. Unwinding propagates to child tasks in `async scope`.
5. `async scope` catches cancellation from its children.

### 42.2 No Error Type Infection

Cancellation does NOT require `From[TaskCancelled]` on user error
types. The unwinding mechanism is separate from the `Result` type
system. User error types (`IoError`, `DbError`, etc.) are unchanged.

`.await` on a cancelled task:
- If the task's return type is `Result[T, E]`: returns a special
  `CancelledError` that can be matched with `.is_cancelled()`.
- If the task returns bare `T`: triggers unwinding in the caller.

The runtime provides `TaskCancelled` as a standard error type that
any `Result` can be checked against, but no `From` impls are needed.

---

*The With Programming Language — End of implementation notes.*