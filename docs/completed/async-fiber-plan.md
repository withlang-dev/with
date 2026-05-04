# Async/Fiber Implementation Plan (v2)

## Context

The With compiler has complete parser, sema, and C runtime
infrastructure for async/fibers — but zero code generation.
All AST nodes parse and type-check. The C runtime (`fiber.c`)
has a working scheduler, channels, and context switching. The
gap: codegen doesn't emit fiber runtime calls.

With's model uses Go-style stackful coroutines with a
cooperative scheduler, not Rust-style state machines.

---

## Architecture: Compiler-Runtime Contract

With's fibers follow Go's G/M/P model adapted for explicit
suspension:

```
Go's goroutines:    implicit scheduling (preemption at safe points)
With's fibers:      explicit scheduling (suspension only at .await)
```

Both are stackful. Both use real stacks per fiber. Both need
compiler cooperation for stack management. The key difference:
With has no preemption — `.await` is the only suspension point,
making the contract simpler.

### Cooperative cancellation

Fibers can only be cancelled at `.await` points. An async
function with no await points cannot be cancelled. This is a
documented property of the cooperative model, not a bug. If a
fiber never yields, it runs to completion regardless of
cancellation requests.

For CPU-bound work that needs cancellation, the user should
insert explicit `check_cancelled()` calls or use threads
instead of fibers. Compiler-inserted cancellation checks at
loop backedges and function prologues (Go's preemption model)
is a v2 consideration.

### What the compiler must emit

1. **Async fn call** → package args into heap struct, generate
   trampoline, heap-allocate result buffer, call
   `with_fiber_spawn` → returns `fiber_id`
2. **`.await`** → call `with_fiber_await(fiber_id)`, check
   cancellation, load result from heap buffer, free buffer
3. **`spawn`** → same as async fn call, discard handle
4. **`async:` block** → lower body as closure, spawn as fiber
5. **`select await`** → evaluate all tasks, call
   `with_fiber_select`, switch on winner index, cancel losers
6. **Channel ops** → `with_channel_send`/`recv` with sized
   element pointers — may suspend internally
7. **Runtime init** → inject `with_runtime_init()` before main,
   `with_runtime_run()` + `with_runtime_shutdown()` after

### What the runtime handles (already implemented in fiber.c)

- Fiber allocation + stack (64KB default, pooled)
- Guard page at bottom of each fiber stack (`PROT_NONE`)
- Context switching (aarch64 + x86_64 asm)
- Scheduler loop with work stealing
- Cooperative yield at await points
- Channel blocking/waking (gopark/goready pattern)
- Cancellation (cooperative flag check at yield)
- Idempotent completion/cancellation state transitions

---

## Runtime Contract

### Function declarations

```
fn with_runtime_init() -> void
fn with_runtime_run() -> void
fn with_runtime_shutdown() -> void

fn with_fiber_spawn(
    entry: fn(*void, *void) -> void,   // trampoline(args, result_buf)
    arg: *void,                         // heap-allocated args struct
    result_buf: *void,                  // heap-allocated result buffer
    result_size: i32,                   // sizeof(return type)
    stack_size: i32,                    // 0 = default (64KB)
) -> i32                                // fiber_id

fn with_fiber_await(fiber_id: i32) -> void
fn with_fiber_is_cancelled() -> bool

fn with_fiber_select(
    ids: *i32,
    count: i32,
    result_index: *i32,
) -> void

fn with_fiber_cancel(fiber_id: i32) -> void

fn with_channel_create(capacity: i32, elem_size: i32) -> i64
fn with_channel_send(ch: i64, value_ptr: *void) -> void
fn with_channel_recv(ch: i64, out_ptr: *void) -> void
fn with_channel_close(ch: i64) -> void
```

### Result passing — heap-allocated sized buffers

The caller heap-allocates the result buffer at spawn time. The
trampoline receives the buffer pointer as an explicit parameter
and writes the return value directly into it. Await loads from
the buffer and frees it.

```
// Spawn side (codegen emits this):
%result_buf = call i8* @with_alloc(i64 sizeof(%ReturnType))
%fid = call i32 @with_fiber_spawn(
    @trampoline, %args, %result_buf, sizeof(%ReturnType), 0)

// Await side:
call void @with_fiber_await(i32 %fid)
%typed = bitcast i8* %result_buf to %ReturnType*
%result = load %ReturnType, %ReturnType* %typed
call void @with_free(i8* %result_buf)
```

**Why heap, not stack:** If the Task escapes its defining scope
(returned from a function, stored in a struct, passed to another
function), a stack-allocated buffer would be a use-after-free.
Escape analysis to optimize to stack alloca is a future
optimization — v1 always heap-allocates. The cost is one
`with_alloc` + `with_free` per async call, negligible compared
to spawning a fiber (which allocates a 64KB stack).

### Trampoline ABI — explicit result buffer parameter

The trampoline receives both the args struct and the result
buffer as explicit parameters. No hidden runtime global state.

```
define void @__async_tramp_FUNCNAME(i8* %env, i8* %result_buf) {
    %args = bitcast i8* %env to %ArgsStruct*
    %a0 = load from getelementptr %args, 0, 0
    %a1 = load from getelementptr %args, 0, 1
    call void @with_free(i8* %env)
    %result = call %RetType @real_fn(%a0, %a1)
    %typed = bitcast i8* %result_buf to %RetType*
    store %RetType %result, %RetType* %typed
    ret void
}
```

The runtime calls `trampoline(args, result_buf)` — both
pointers were passed to `with_fiber_spawn` and stored in the
fiber struct. The trampoline's behavior is fully determined
by its arguments. No implicit dependency on "current fiber"
state.

### Channel slots — sized elements

The channel knows element size at creation. Send copies
`elem_size` bytes from the value pointer into the channel's
internal buffer. Recv copies `elem_size` bytes out.

```
// Send:
%slot = alloca %ElemType
store %ElemType %value, %ElemType* %slot
call void @with_channel_send(i64 %ch, i8* %slot)

// Recv:
%slot = alloca %ElemType
call void @with_channel_recv(i64 %ch, i8* %slot)
%value = load %ElemType, %ElemType* %slot
```

Handles every type uniformly. No casting, no boxing. Same
pattern as Go's `chansend`/`chanrecv`.

### Fiber lifecycle semantics

**Completion and cancellation are idempotent and mutually
exclusive.** A fiber's state transitions are:

```
running → completed
running → cancelled
```

Both are final. Attempting the other transition after one has
occurred is a no-op. The runtime guarantees no double-write to
result buffers. Implementation: compare-and-swap on the fiber's
state field. The result buffer write happens before the
`completed` flag is set (store ordering).

**Panic in a fiber:** The panic is captured and stored in the
fiber struct. When the fiber is awaited, the panic re-raises in
the awaiting fiber. If the fiber is never awaited (fire-and-
forget spawn), the panic is printed to stderr during
`with_runtime_run()` drain and the program exits with a
non-zero code.

**`with_runtime_run()` semantics:** Blocks until all spawned
fibers complete. Main is not a fiber — it is the thread that
runs the scheduler. After main returns:
- `with_runtime_run()` drains all pending fibers
- If any fiber panicked and was not awaited, print the panic
  and set exit code to 1
- `with_runtime_shutdown()` cancels all remaining fibers,
  waits for them to unwind, then releases pools and scheduler
  state

### Stack safety

Each fiber stack has a guard page (`PROT_NONE` or equivalent)
at its lowest address. Stack overflow hits the guard page and
produces an immediate, deterministic signal (SIGSEGV/
SIGBUS). The runtime installs a signal handler that prints
"fiber stack overflow" with the fiber's ID and the offending
function, then aborts. No silent corruption.

Guard pages are allocated as part of fiber stack setup in
`fiber.c`. Cost: one extra page (4KB-16KB) per fiber. This is
non-negotiable — silent stack corruption is unacceptable.

---

## Phase 1: Task[T] Type System

### 1a. Define Task[T]

Task is a struct wrapping an i32 fiber_id plus a pointer to
the heap-allocated result buffer. The `T` parameter exists for
sema type checking.

File: `lib/std/async.w`:
```
pub type Task[T] {
    fiber_id: i32,
    result_buf: *mut u8,
}
```

The result buffer pointer is needed at await time to load the
result and free the buffer.

### 1b. Async fn return type wrapping

When `FnFlags.ASYNC` is set, sema wraps the declared return
type `T` in `Task[T]`.

File: `src/SemaDecl.w` — in `collect_fn_decl`, after resolving
return type:
```
if (flags / FnFlags.ASYNC) % 2 == 1:
    let task_sym = self.pool_intern("Task")
    let args: Vec[i32] = Vec.new()
    args.push(ret_type as i32)
    let task_ty = self.find_or_create_generic_inst(task_sym, args, 1)
    ret_type = task_ty
```

File: `src/SemaCheck.w` — in `check_fn_body`, when ASYNC flag,
the body's expected type is the unwrapped `T`, not `Task[T]`.
The fiber wrapping happens at the call site, not inside the body.

### 1c. `.await` in non-async context is a compile error

File: `src/SemaCheck.w` — in `check_await`:
```
if not self.current_fn_is_async():
    self.emit_error("await requires async context", node)
    return self.ty_error
```

`.await` in `fn main` or any non-async function is a compile
error. For blocking on a task from sync code, use an explicit
`block_on(task)` wrapper that internally initializes and runs
the scheduler. This keeps the async boundary explicit.

---

## Phase 2: Runtime Initialization + Guard Pages

Programs using async must initialize the fiber runtime before
any spawn occurs. This phase comes before spawn codegen so that
every intermediate test during development has a working runtime.

### 2a. Runtime init in `__with_main`

File: `src/Codegen.w` — in `__with_main` generation:
```
if program_uses_async:
    call @with_runtime_init()
call @main()
if program_uses_async:
    call @with_runtime_run()
    call @with_runtime_shutdown()
```

Detection: scan all function declarations for `FnFlags.ASYNC`,
or check if any MIR body uses fiber intrinsics. Store as a
boolean on the module.

### 2b. Guard pages

File: `fiber.c` — in fiber stack allocation, add guard page:
```
// Allocate stack + guard page
void* stack = mmap(NULL, stack_size + page_size,
                   PROT_READ | PROT_WRITE,
                   MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
// Guard page at low end
mprotect(stack, page_size, PROT_NONE);
// Usable stack starts above guard
fiber->stack_base = stack + page_size;
fiber->stack_size = stack_size;
```

Install a signal handler for SIGSEGV/SIGBUS that detects
whether the fault address falls within a fiber's guard page
and prints a diagnostic before aborting.

### 2c. Smoke test

```
// test/behavior/behav_async_runtime_init.w
//! expect-stdout: ok

fn main:
    // Just verify the program runs with async infrastructure
    // initialized, even if no async calls are made.
    print("ok")
```

This verifies that `with_runtime_init()` / `run()` / `shutdown()`
don't crash when no fibers are spawned.

---

## Phase 3: MIR Intrinsics

Add MIR intrinsics so MIR lowering can represent spawn/await
as structured operations.

```
MIR_INTRINSIC_FIBER_SPAWN     // (fn_sym, args...) -> Task[T]
MIR_INTRINSIC_FIBER_AWAIT     // (task) -> T
MIR_INTRINSIC_FIBER_SELECT    // (tasks...) -> (index, result)
MIR_INTRINSIC_FIBER_CANCEL    // (task) -> void
```

File: `src/Mir.w` — add to intrinsic enum.

File: `src/MirLower.w`:
- `NK_SPAWN` → emit `MIR_INTRINSIC_FIBER_SPAWN`
- `NK_AWAIT` → emit `MIR_INTRINSIC_FIBER_AWAIT`
- `NK_SELECT_AWAIT` → emit `MIR_INTRINSIC_FIBER_SELECT`
- `task.cancel()` → emit `MIR_INTRINSIC_FIBER_CANCEL`

---

## Phase 4: Codegen — Async Fn Call → Fiber Spawn

When codegen encounters `MIR_INTRINSIC_FIBER_SPAWN`:

### 4a. Arg packaging

Heap-allocate a struct containing all arguments:
```
%ArgsStruct = type { %Arg0Type, %Arg1Type, ... }
%args = call i8* @with_alloc(i64 sizeof(%ArgsStruct))
%arg0_ptr = getelementptr %ArgsStruct, %ArgsStruct* %args, i32 0, i32 0
store %Arg0Type %a0, %Arg0Type* %arg0_ptr
// ... for each arg
```

### 4b. Trampoline generation — one per async function

Generate one trampoline per async function, cached by function
symbol:

```
define void @__async_tramp_FUNCNAME(i8* %env, i8* %result_buf) {
    %args = bitcast i8* %env to %ArgsStruct*
    %a0 = load from getelementptr %args, 0, 0
    %a1 = load from getelementptr %args, 0, 1
    call void @with_free(i8* %env)
    %result = call %RetType @real_fn(%a0, %a1)
    %typed = bitcast i8* %result_buf to %RetType*
    store %RetType %result, %RetType* %typed
    ret void
}
```

File: `src/Codegen.w` — add trampoline cache:
```
async_trampolines: HashMap[i32, i64],  // fn_sym → LLVMValueRef
```

Lookup before generating:
```
if not self.async_trampolines.contains(fn_sym):
    let tramp = self.generate_async_trampoline(fn_sym)
    self.async_trampolines.insert(fn_sym, tramp)
let tramp = self.async_trampolines.get(fn_sym)
```

### 4c. Spawn emission

```
// Heap-allocate result buffer
%result_buf = call i8* @with_alloc(i64 sizeof(%ReturnType))

// Spawn fiber
%fid = call i32 @with_fiber_spawn(
    @__async_tramp_FUNCNAME,
    %args_ptr,
    %result_buf,
    sizeof(%ReturnType),
    0                                   // default stack size
)

// Construct Task { fiber_id, result_buf }
%task0 = insertvalue { i32, i8* } undef, i32 %fid, 0
%task  = insertvalue { i32, i8* } %task0, i8* %result_buf, 1
```

---

## Phase 5: Codegen — Await

When codegen encounters `MIR_INTRINSIC_FIBER_AWAIT`:

```
// Extract fiber_id and result_buf from Task
%fid = extractvalue { i32, i8* } %task, 0
%result_buf = extractvalue { i32, i8* } %task, 1

// Suspend until fiber completes
call void @with_fiber_await(i32 %fid)

// Check cancellation — unwind if cancelled
%cancelled = call i1 @with_fiber_is_cancelled()
br i1 %cancelled, label %unwind, label %continue

%continue:
// Load result from heap buffer
%typed = bitcast i8* %result_buf to %ReturnType*
%result = load %ReturnType, %ReturnType* %typed
// Free the result buffer
call void @with_free(i8* %result_buf)
```

The `%unwind` label triggers the cleanup path — runs defers,
frees the result buffer, propagates cancellation to the caller.

### Cancellation unwind

The unwind path must:
1. Free the result buffer (it was heap-allocated at spawn)
2. Run any defers in the current scope
3. Propagate cancellation — if this fiber was awaiting because
   another fiber awaited it, the cancellation chains upward

---

## Phase 6: Test — Basic Async/Await End-to-End

Before adding more features, verify the core works:

```
// test/behavior/behav_async_basic.w
//! expect-stdout: ok

async fn double(x: i32) -> i32:
    x * 2

fn main:
    let task = double(21)
    let result = task.await
    assert(result == 42)
    print("ok")
```

This exercises: Task[T] type wrapping, trampoline generation,
arg packaging, heap result buffer, spawn, await, cancellation
check, buffer free, runtime init/run/shutdown.

```
// test/behavior/behav_async_multiple.w
//! expect-stdout: ok

async fn add(a: i32, b: i32) -> i32:
    a + b

fn main:
    let t1 = add(10, 20)
    let t2 = add(30, 40)
    let r1 = t1.await
    let r2 = t2.await
    assert(r1 == 30)
    assert(r2 == 70)
    print("ok")
```

Verifies multiple concurrent fibers with independent result
buffers.

```
// test/behavior/behav_async_escape.w
//! expect-stdout: ok

async fn compute(x: i32) -> i32:
    x * x

fn spawn_task() -> Task[i32]:
    compute(7)   // Task escapes defining scope

fn main:
    let t = spawn_task()
    let r = t.await   // must work — result buffer is heap-allocated
    assert(r == 49)
    print("ok")
```

Verifies that Task escaping its defining scope doesn't corrupt
the result buffer (heap allocation makes this safe).

```
// test/behavior/behav_async_struct_return.w
//! expect-stdout: ok

type Point { x: f64, y: f64 }

async fn make_point(x: f64, y: f64) -> Point:
    Point { x, y }

fn main:
    let t = make_point(3.0, 4.0)
    let p = t.await
    assert(p.x == 3.0)
    assert(p.y == 4.0)
    print("ok")
```

Verifies sized result buffers work for types larger than a
register.

---

## Phase 7: Async Blocks

`async: body` creates an anonymous closure, spawns it as a
fiber, returns `Task[T]`.

```
let task: Task[i32] = async:
    let x = expensive_computation()
    x + 1
let result = task.await
```

Codegen:
1. Lower body as a closure (reuse existing closure lowering)
2. Generate trampoline for the closure type
3. Spawn the closure's function pointer with captured env as
   the args struct (same mechanism as async fn calls)
4. Heap-allocate result buffer
5. Return `Task { fiber_id, result_buf }`

---

## Phase 8: Select Await

```
select await:
    data = fetch_task => process(data)
    msg = listen_task => handle(msg)
    _ = timeout_task => return Err(.Timeout)
```

Codegen:
1. Evaluate all arm task expressions → extract fiber_ids
2. Pack fiber_ids into `i32[]` array on stack
3. Call `with_fiber_select(ids, count, &winner_index)`
4. Switch on `winner_index`:
   - Load result from the winning task's result buffer
   - Free the winning result buffer
   - Bind to arm variable
   - Execute arm body
5. Cancel non-winning fibers, free their result buffers

```
%ids = alloca [3 x i32]
store i32 %fid0, [3 x i32]* %ids, 0, 0
store i32 %fid1, [3 x i32]* %ids, 0, 1
store i32 %fid2, [3 x i32]* %ids, 0, 2
%winner = alloca i32
call void @with_fiber_select(
    i32* %ids, i32 3, i32* %winner)
%idx = load i32, i32* %winner
switch i32 %idx, label %unreachable [
    i32 0, label %arm0
    i32 1, label %arm1
    i32 2, label %arm2
]
```

### Cancellation of losers

After the selected arm executes, cancel all non-winning fibers:
```
%arm0:
    ; load winner result, free buffer, execute body
    ; then cancel losers:
    call void @with_fiber_cancel(i32 %fid1)
    call void @with_fiber_cancel(i32 %fid2)
    call void @with_free(i8* %result_buf1)
    call void @with_free(i8* %result_buf2)
    br label %join
```

`with_fiber_cancel` on an already-completed fiber is a no-op
(idempotent completion). A losing fiber that completed between
the select returning and the cancel call is handled safely —
no double-write, no use-after-free.

---

## Phase 9: Channels

File: `lib/std/async.w`:
```
pub type Channel[T] { handle: i64 }
pub type Sender[T] { ch: i64 }
pub type Receiver[T] { ch: i64 }

pub fn chan[T](capacity: i32) -> (Sender[T], Receiver[T]):
    let h = with_channel_create(capacity, size_of[T]())
    (Sender { ch: h }, Receiver { ch: h })
```

Codegen for `sender.send(value)`:
```
%slot = alloca %ElemType
store %ElemType %value, %ElemType* %slot
call void @with_channel_send(i64 %ch, i8* %slot)
```

Codegen for `let value = receiver.recv()`:
```
%slot = alloca %ElemType
call void @with_channel_recv(i64 %ch, i8* %slot)
%value = load %ElemType, %ElemType* %slot
```

Send and recv may suspend the fiber internally — the C runtime
handles this via its gopark/goready mechanism. From the
compiler's perspective, they're ordinary function calls that
happen to yield.

### Channel in select

Channels in `select await` arms require the runtime's select
to accept heterogeneous wait sources (fiber completion vs
channel readiness). This is the same unification Go's select
does. Defer to a follow-up — v1 select supports tasks only.

---

## Phase 10: Stack Size Annotation

```
@[stack_size(262144)]  // 256KB
async fn process_large(data: &Buffer) -> Result[Output, Error]:
    ...
```

Codegen reads the annotation and passes the size to
`with_fiber_spawn`'s `stack_size` parameter. Default 0 means
the runtime uses 64KB.

The spec's `@[ffi_stack]` annotation is a special case — it
could either set a large stack size or switch the fiber to run
on the system stack for the duration of the FFI call. Design
details deferred.

---

## Phase 11: Full Test Suite

### Behavior tests

```
behav_async_basic.w          — async fn + .await
behav_async_multiple.w       — multiple concurrent tasks
behav_async_escape.w         — Task escaping defining scope
behav_async_struct_return.w  — async fn returning large struct
behav_async_spawn.w          — spawn fire-and-forget
behav_async_scope.w          — async scope with s.track()
behav_async_select.w         — select await
behav_async_block.w          — async: inline block
behav_async_tuple_await.w    — (t1, t2).await
behav_async_cancel.w         — task.cancel() + propagation
behav_async_cancel_noop.w    — cancel already-completed task
behav_async_result.w         — ? in async context
behav_async_panic.w          — panic in fiber re-raises at await
behav_async_stack_overflow.w — deep recursion in fiber → clean error
behav_channel_basic.w        — send/recv
behav_channel_bounded.w      — bounded backpressure
behav_channel_close.w        — close + recv after close
```

### Compile-error tests

```
err_await_outside_async.w    — .await in non-async fn → error
err_await_in_comptime.w      — .await in comptime → error
err_unused_task.w            — Task not awaited → must_use warning
err_suspend_under_guard.w    — .await while holding lock → E0701
```

---

## Key Design Decisions

| Decision | Rationale |
|---|---|
| Heap-allocated result buffers | Task can escape its defining scope. Stack alloca would be use-after-free. Heap cost is negligible vs fiber spawn cost. Stack alloca as future optimization via escape analysis. |
| Explicit result_buf parameter in trampoline | No hidden runtime global state. Trampoline behavior fully determined by arguments. Easier to test and debug. |
| One trampoline per async function | Cached by function symbol. Avoids O(call sites) code generation. |
| Runtime init before spawn codegen | Every intermediate test needs the runtime. Prevents false-negative segfaults during development. |
| Cancellation check at every `.await` | Makes cooperative cancellation work. Without it, cancelled fibers resume and continue. |
| `.await` outside async = compile error | Keeps async boundary explicit. `block_on()` is the escape hatch. |
| Sized channel slots | Pointer to element, not i64 cast. Handles all types uniformly. |
| Cooperative cancellation only at `.await` | Simpler than Go's preemption. Documented limitation. CPU-bound work should use threads. |
| Guard pages on fiber stacks | Silent stack corruption is unacceptable. One guard page per fiber. Clean error on overflow. |
| Idempotent completion/cancellation | Prevents races in select. CAS on fiber state. Result write before completion flag. |
| Panic capture in fiber | Re-raise at await. Unhandled panics printed during drain. Matches Go's behavior. |
| `with_runtime_run()` drains all fibers | Main is not a fiber. Explicit drain after main returns. No implicit background work after exit. |
| No stack growth (v1) | Fixed 64KB + guard page. Configurable via `@[stack_size]`. Growable stacks (compiler-inserted morestack) deferred to v2. |
| No preemption (v1) | Cooperative model is simpler and sufficient for I/O-bound workloads. Preemption (loop backedge checks) deferred to v2. |
| No GC integration | With has no garbage collector. Go's GC complexity doesn't apply. |
| Channel select deferred | v1 select supports tasks only. Channel select requires heterogeneous wait sources in the runtime. |

---

## Verification

After each phase:
- `make build` + `make fixpoint`
- Phase-specific test (starting Phase 6)

After Phase 6 (basic async/await):
- All four Phase 6 tests pass
- No regressions in sync code (`make test` passes)

Final:
- `make test` — all existing tests pass + all new async tests
- No regressions in sync code (async is additive)

---

## Dependencies

```
Phase 1 (type system)     — no dependencies
Phase 2 (runtime init)    — no dependencies
Phase 3 (MIR intrinsics)  — Phase 1
Phase 4 (spawn codegen)   — Phase 2, Phase 3
Phase 5 (await codegen)   — Phase 4
Phase 6 (basic tests)     — Phase 5
Phase 7 (async blocks)    — Phase 6
Phase 8 (select)          — Phase 6
Phase 9 (channels)        — Phase 6
Phase 10 (stack size)     — Phase 4
Phase 11 (full tests)     — all above
```

Phases 7, 8, 9, 10 are independent of each other and can be
implemented in any order after Phase 6 proves the core works.