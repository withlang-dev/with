# Fiber Backend Migration: minicoro

Replace the current platform-specific fiber backend with a minicoro-backed fiber backend, gaining cross-platform coroutine support without changing async language semantics.

The scheduler, scope tracking, cancellation, channels, and all async language constructs stay owned by With. minicoro provides only the context switch substrate.

---

## 1. Motivation

The current fiber backend (`rt/fiber_core_darwin.w`, `rt/fiber_asm_darwin.s`) is:

- **Darwin/aarch64 only.** No x86_64, no Linux, no Windows, no RISC-V, no WebAssembly.
- **Hand-written assembly** for context switching with manual signal handling for stack overflow.
- **Fixed stack allocation** via mmap with guard pages. No growable stacks, no virtual memory backed allocator.
- **Hardcoded limit** of 1024 live fibers.
- **No sanitizer support.** Cannot run under Valgrind, ASan, or TSan.

minicoro provides:

- **Cross-platform assembly backends:** x86_64, ARM, ARM64, RISC-V, with ucontext and Windows fiber fallbacks.
- **WebAssembly support** via Emscripten fibers or Binaryen asyncify.
- **Virtual memory backed growable stacks** (`MCO_USE_VMEM_ALLOCATOR`) for thousands of coroutines with low physical memory footprint.
- **Sanitizer compatibility:** Valgrind, ASan, TSan.
- **Battle-tested** in production use by the Nelua programming language.
- **~1800 lines of clean C** under Public Domain / MIT No Attribution.

---

## 2. Architecture

### 2.1 Target layering

```
async fn / await / select await       (language)
        |
        v
  MIR intrinsics                       (compiler)
  FIBER_AWAIT, FIBER_SELECT,
  FIBER_CLEANUP_AWAIT
        |
        v
  With scheduler + task runtime        (rt/fiber_runtime.w)
  ready queues, run loop,
  scope tracking, cancellation
        |
        v
  fiber backend interface              (rt/fiber_backend.w)
  fiber_create, fiber_resume,
  fiber_yield, fiber_destroy,
  fiber_running
        |
        v
  minicoro (migrated)                  (rt/minicoro.w)
  mco_create, mco_resume,
  mco_yield, mco_destroy
```

The backend interface is a permanent abstraction. It stays even after the old backend is removed. It is insurance for WASM targets, debug backends, sanitizer builds, or future custom backends.

### 2.2 What changes

| Component | Before | After |
|---|---|---|
| Context switch | `fiber_asm_darwin.s` (aarch64 only) | minicoro assembly (multi-arch) |
| Stack allocation | Manual mmap + guard pages | minicoro allocator (mmap or vmem) |
| Coroutine creation | `with_fiber_prepare_initial_context` | `mco_create` via backend wrapper |
| Yield/resume | `with_fiber_switch` (custom asm) | `mco_yield` / `mco_resume` |
| Current coroutine | Global `current_fiber_id` | `mco_running()` + backend mapping |
| Platform support | Darwin/aarch64 | x86_64, ARM, ARM64, RISC-V, WebAssembly, Windows |

### 2.3 What does not change

| Component | Reason |
|---|---|
| `Task[T]` type and semantics | Language-level construct, above the backend |
| `await` lowering | MIR intrinsic, calls into scheduler not backend |
| `select await` lowering | MIR intrinsic, calls into scheduler not backend |
| Cancellation propagation | Scheduler responsibility, not backend |
| `async scope` / structured concurrency | Scope tracking, above the backend |
| Channels (`chan[T]`, `Sender`, `Receiver`) | Cooperative queue, calls yield not backend directly |
| Result buffers (heap-allocated return values) | Codegen responsibility |
| Async function trampolines | Codegen responsibility |
| `async fn` signature transformation | Sema responsibility |

### 2.4 Blocking call policy

minicoro provides coroutine switching, not an IO reactor. This remains true after migration:

A blocking syscall inside a fiber blocks the entire OS thread. Nonblocking IO or worker-thread offloading are separate concerns not addressed by this migration.

---

## 3. Prerequisites: Fix Known Async Bugs

Before starting the migration, fix the five known bugs from the async review. This establishes a clean behavioral baseline so migration regressions are distinguishable from pre-existing issues.

### 3.1 Scope tracking growth (use-after-free)

**Location:** `rt/rt_core.w:2488`

**Bug:** `with_scope_track(handle, fiber_id)` takes the scope handle by value. When `count` reaches `capacity`, it allocates a new buffer, copies, frees the old buffer, and recursively tracks into the new handle. The caller still holds the freed old handle.

**Fix:** Make the scope handle point to a stable heap-allocated scope object whose internal ID buffer can grow in place. The handle becomes a pointer to the scope, not the scope itself.

**Test:** Create an async scope that tracks more than 16 tasks.

### 3.2 Select-await typing

**Location:** `src/MirLower.w:5962`

**Bug:** Select await lowers the awaited winner using `self.expr_type(node)`, which is the select expression's result type, not the selected task's inner `Task[T]` type. If task result types differ from arm body result types, the bound value is wrong.

**Fix:** Derive the arm binding type from the unwrapped `Task[T]` result type of each arm's task expression, not from the select expression's overall type.

**Test:** Select await between `Task[i32]` and `Task[str]` with different arm body types.

### 3.3 Select-await no-ready path

**Location:** `rt/fiber_runtime.w:82`, `src/MirLower.w:5945`

**Bug:** `with_fiber_select` can return -1 when no fibers remain. MIR lowers the default/unknown case to the join block, returning an uninitialized select result.

**Fix:** Emit a runtime panic on the -1 path: "select await: no tasks completed."

**Test:** Select await on already-completed or cancelled tasks.

### 3.4 Await result type derivation

**Location:** `src/CodegenDispatch.w:4806`

**Bug:** Await result loading falls back through four sources: `async_task_result_types` keyed by MIR local, destination type, `last_async_spawn_ret_ty`, then `i32`. This is fragile for task values flowing through containers, function returns, or copies.

**Fix:** Derive the result type from the sema type of the awaited `Task[T]` expression. The unwrapped `T` is the result type. No fallback chain needed.

**Test:** Await a task value stored in a struct field, returned from a function, and copied between variables.

### 3.5 `await_first` semantics

**Location:** `lib/std/task.w:49`

**Bug:** `await_first` awaits index 0, then cancels the rest. This is "await the first in the list," not "await whichever completes first."

**Fix:** Implement using `select await` or a runtime multi-await primitive that returns whichever task completes first.

**Test:** Two tasks with different sleep durations; `await_first` should return the faster one.

### 3.6 Panic and defer edge cases

Add explicit tests for these async contract paths:

- Fiber panics before first yield
- Fiber panics after yield
- Fiber returns normally with active defers
- Fiber cancelled while inside nested defers
- Await of panicked task reports correctly
- `runtime_run` reports unhandled panic

These test the scheduler-level contract, not the backend, but they must pass on both backends during dual-backend testing.

---

## 4. Phase 1: Introduce Backend Interface

Introduce the abstraction while the current backend still works. This verifies the interface design against known-good behavior before minicoro enters the picture.

### 4.1 Define the interface

Create `rt/fiber_backend.w`:

```with
// rt/fiber_backend.w

/// Opaque backend fiber handle. Prevents accidental mixing with
/// arbitrary byte pointers.
type FiberHandle = distinct *mut i8

/// Lifecycle states as seen by the scheduler.
/// The backend reports these; the scheduler acts on them.
enum FiberState: i32:
    Suspended = 0
    Running = 1
    Dead = 2

/// Entry function signature for a fiber.
type FiberEntryFn = fn(*mut i8) -> void

/// Initialize the backend. Must be called before any other
/// fiber_backend_* function. This is where platform-specific
/// setup belongs:
///   - Windows: ConvertThreadToFiber for the main thread
///   - Debug builds: counter/sanitizer initialization
///   - Allocator setup
/// Returns 0 on success, nonzero on failure.
fn fiber_backend_init() -> i32

/// Shut down the backend. Called after the scheduler is done.
/// Releases any global backend resources.
/// Returns 0 on success, nonzero on failure.
fn fiber_backend_shutdown() -> i32

/// Create a new fiber. Returns an opaque handle, or null on failure.
/// The backend stores user_data and returns it via
/// fiber_backend_user_data, but does not own it. The scheduler/task
/// runtime is responsible for allocation and cleanup of the data
/// pointed to by user_data.
fn fiber_backend_create(entry: FiberEntryFn, user_data: *mut i8, stack_size: i64) -> FiberHandle

/// Resume a suspended fiber. Returns when the fiber yields or completes.
/// Panics in debug builds if handle is null or fiber is not suspended.
fn fiber_backend_resume(handle: FiberHandle) -> i32

/// Yield the currently running fiber. Returns when resumed.
/// Panics in debug builds if called from the scheduler/main context
/// (i.e. when fiber_backend_is_inside_fiber() is false).
fn fiber_backend_yield() -> i32

/// Destroy a fiber. Must be dead or suspended.
/// Does not free user_data; the scheduler owns that.
fn fiber_backend_destroy(handle: FiberHandle) -> i32

/// Get the currently running fiber's handle.
/// Returns null (as FiberHandle) if not inside a fiber.
fn fiber_backend_running() -> FiberHandle

/// Returns true if the current execution context is inside a fiber,
/// false if in the scheduler/main context.
fn fiber_backend_is_inside_fiber() -> bool

/// Get user data for a fiber. The backend stores and returns this
/// pointer without owning it. The scheduler/task runtime owns
/// whatever the pointer refers to.
fn fiber_backend_user_data(handle: FiberHandle) -> *mut i8

/// Get the lifecycle state of a fiber.
fn fiber_backend_state(handle: FiberHandle) -> FiberState
```

Key design decisions:

- **Distinct opaque type.** `FiberHandle = distinct *mut i8` prevents passing arbitrary byte pointers where a fiber handle is expected. Runtime code loves turning "opaque pointer" into "any pointer fits." The distinct type catches that at compile time.
- **Init/shutdown lifecycle.** `fiber_backend_init()` and `fiber_backend_shutdown()` give a clean place for platform setup (Windows fiber conversion, thread-local state, debug counters, sanitizer hooks, allocator registration) without polluting create/destroy paths.
- **Convenience predicate.** `fiber_backend_is_inside_fiber()` is one line internally but reads better than null-checking `fiber_backend_running()` in assertions and guards.
- **Lifecycle states at the wrapper layer.** `FiberState` is defined by With, not by minicoro. The backend maps its internal states to these.
- **user_data ownership.** Explicitly documented: the backend stores and returns the pointer without owning it. The scheduler/task runtime allocates and frees the environment/trampoline data.
- **Debug assertions.** `fiber_backend_yield()` panics if not inside a fiber. `fiber_backend_resume()` panics if the fiber is not suspended.

### 4.2 Wrap current backend

Create `rt/fiber_backend_current.w` that wraps the existing `fiber_core_darwin.w` behind the new interface:

| Backend function | Current implementation |
|---|---|
| `fiber_backend_init` | No-op on Darwin (main context is not a fiber) |
| `fiber_backend_shutdown` | No-op |
| `fiber_backend_create` | `with_fiber_prepare_initial_context` + enqueue |
| `fiber_backend_resume` | `with_fiber_switch` |
| `fiber_backend_yield` | `with_fiber_switch` back to scheduler |
| `fiber_backend_destroy` | Free fiber stack and slot |
| `fiber_backend_running` | Map current `current_fiber_id` to handle |
| `fiber_backend_is_inside_fiber` | `current_fiber_id != 0` |
| `fiber_backend_user_data` | Look up stored user_data by handle |
| `fiber_backend_state` | Map fiber slot status to `FiberState` |

### 4.3 Rewire scheduler

Replace direct `fiber_core_darwin.w` calls in `rt/fiber_runtime.w` with `fiber_backend_*` calls:

| Current call | Replacement |
|---|---|
| (startup) | `fiber_backend_init()` |
| `with_fiber_spawn(...)` | `fiber_backend_create(...)` + scheduler enqueue |
| `with_fiber_switch(...)` | `fiber_backend_resume(...)` |
| `with_fiber_yield()` | `fiber_backend_yield()` |
| `with_fiber_destroy(...)` | `fiber_backend_destroy(...)` |
| `current_fiber_id` global | `fiber_backend_running()` + scheduler lookup |
| (shutdown) | `fiber_backend_shutdown()` |

### 4.4 Verify no behavior change

Run the full async test suite. Every test that passed before the abstraction must still pass.

---

## 5. Phase 2: Migrate minicoro to With

### 5.1 Obtain source

```bash
# Pin to a specific commit for reproducibility
curl -L https://raw.githubusercontent.com/edubart/minicoro/<commit>/minicoro.h \
    -o .reference/minicoro/minicoro.h
```

### 5.2 Prepare for migration

```bash
mkdir -p .reference/minicoro
cat > .reference/minicoro/minicoro.c << 'EOF'
#define MINICORO_IMPL
#define MCO_USE_VMEM_ALLOCATOR
#include "minicoro.h"
EOF
```

### 5.3 Migrate

```bash
with migrate .reference/minicoro/minicoro.c \
    -o out/minicoro_migrated/ \
    --no-c-export \
    --prefer-brace \
    -I .reference/minicoro
```

The migration will test:

- Platform `#ifdef` handling (minicoro has extensive conditional compilation)
- Inline assembly passthrough (context switch implementations)
- Union handling (minicoro uses unions for register save areas)
- Function pointer callbacks (`mco_desc.func`, allocator callbacks)

### 5.4 Platform-specific assembly

minicoro's assembly context switch code is guarded by `#ifdef MCO_USE_ASM`. The migrator may not translate inline assembly. If so, keep the assembly in separate `.s` files linked alongside the migrated With code:

```
rt/minicoro.w              -- migrated C logic
rt/minicoro_asm_aarch64.s  -- context switch for aarch64
rt/minicoro_asm_x86_64.s   -- context switch for x86_64
```

### 5.5 Custom allocator hookup

Use minicoro's allocator callbacks to route through With's allocator:

```with
var desc = mco_desc_init(entry_fn, stack_size)
desc.alloc_cb = with_fiber_alloc
desc.dealloc_cb = with_fiber_dealloc
```

### 5.6 Verify standalone

```with
// test/behavior/behav_minicoro_basic.w
use rt.minicoro

fn coro_body(co: *mut mco_coro):
    mco_yield(co)

fn main:
    var desc = mco_desc_init(coro_body, 0)
    var co: *mut mco_coro = null
    assert(mco_create(&raw mut co, &raw mut desc) == MCO_SUCCESS)
    assert(mco_status(co) == MCO_SUSPENDED)
    assert(mco_resume(co) == MCO_SUCCESS)
    assert(mco_status(co) == MCO_SUSPENDED)
    assert(mco_resume(co) == MCO_SUCCESS)
    assert(mco_status(co) == MCO_DEAD)
    assert(mco_destroy(co) == MCO_SUCCESS)
    print("ok")
```

---

## 6. Phase 3: Minicoro Backend + Dual Testing

### 6.1 Implement minicoro backend

Create `rt/fiber_backend_minicoro.w`:

- Casts `FiberHandle` (distinct `*mut i8`) to/from `mco_coro*`
- `fiber_backend_init`: platform allocator setup, Windows `ConvertThreadToFiber` if needed
- `fiber_backend_shutdown`: cleanup of any global backend state
- Maps `FiberState` to minicoro's `MCO_SUSPENDED` / `MCO_RUNNING` / `MCO_DEAD`
- `fiber_backend_is_inside_fiber`: `mco_running() != null`
- Implements all remaining `fiber_backend_*` functions using `mco_*` calls
- Adds debug assertions for yield-from-main and resume-non-suspended

### 6.2 Backend selection

```bash
with build myapp.w --fiber-backend=minicoro
with build myapp.w --fiber-backend=current
```

The linker includes either `fiber_backend_minicoro.o` or `fiber_backend_current.o`. The interface in `fiber_backend.w` is the same either way.

### 6.3 Test matrix

```bash
scripts/run_tests.sh test/behavior/behav_async_*.w --fiber-backend=current
scripts/run_tests.sh test/behavior/behav_async_*.w --fiber-backend=minicoro

scripts/run_tests.sh test/behavior/behav_channel_*.w --fiber-backend=current
scripts/run_tests.sh test/behavior/behav_channel_*.w --fiber-backend=minicoro

scripts/run_tests.sh test/behavior/behav_scope_*.w --fiber-backend=current
scripts/run_tests.sh test/behavior/behav_scope_*.w --fiber-backend=minicoro

scripts/run_tests.sh test/behavior/behav_fiber_panic_*.w --fiber-backend=current
scripts/run_tests.sh test/behavior/behav_fiber_panic_*.w --fiber-backend=minicoro
```

### 6.4 Destroy-while-suspended test

```with
fn yielding_fiber(co: *mut i8):
    fiber_backend_yield()
    // never reached

fn main:
    fiber_backend_init()
    let handle = fiber_backend_create(yielding_fiber, null, 0)
    fiber_backend_resume(handle)
    assert(fiber_backend_state(handle) == FiberState.Suspended)
    assert(fiber_backend_destroy(handle) == 0)
    fiber_backend_shutdown()
    print("ok")
```

This must not leak the fiber's stack or crash.

### 6.5 Acceptance criteria

- All tests that pass on `current` must also pass on `minicoro`.
- All pre-existing bug fixes (section 3) must pass on both backends.
- No new test failures introduced by the migration.

### 6.6 Performance comparison

Measure context switch cost on both backends. Performance criterion: context switch performance is comparable to the old backend, or any regression is understood and accepted. Cross-platform correctness is worth a small slowdown. A 5-15% backend difference should not block the migration if the overall async runtime becomes portable and testable.

---

## 7. Phase 4: Promote and Clean Up

### 7.1 Platform targets

Migration is complete when async tests pass on all three primary targets:

| Platform | Priority |
|---|---|
| Darwin/aarch64 | Required |
| Linux/x86_64 | Required |
| Windows/x86_64 | Required |

Additional targets (Linux/aarch64, macOS/x86_64, RISC-V, WebAssembly) are future work enabled by minicoro but not required for declaring the migration complete.

### 7.2 Remove old backend

Once minicoro passes on all three primary platforms:

- Delete `rt/fiber_core_darwin.w`
- Delete `rt/fiber_asm_darwin.s`
- Delete `rt/fiber_backend_current.w`
- Remove `--fiber-backend=current` flag
- Make minicoro the default and only backend

### 7.3 Keep the backend interface

`rt/fiber_backend.w` stays permanently. It is the seam for:

- Future WASM-specific backends
- Debug/instrumentation backends
- Sanitizer-friendly stub backends
- Any future context switch implementation

### 7.4 `mco_*` audit rule

`mco_*` symbols may appear only in:

```
rt/minicoro.w
rt/fiber_backend_minicoro.w
test/behavior/behav_minicoro_basic.w
```

No `mco_*` in any `lib/std/` file, any `src/` compiler file, any public type signature, any error message, or any diagnostic. Enforceable with:

```bash
rg 'mco_' lib/std/ src/ --include '*.w' && echo "FAIL: mco_ leaked" || echo "OK"
```

### 7.5 Update linking

`src/compiler/Link.w` currently links `fiber_runtime.o`, `fiber.o`, `fiber_asm.o`. Update to:

- `fiber_runtime.o` (scheduler, unchanged)
- `fiber_backend_minicoro.o` (backend wrapper)
- `minicoro.o` (migrated minicoro)
- Platform-specific assembly objects as needed

---

## 8. Ordering Summary

```
Step 0:  Fix 5 known async bugs + add panic/defer tests   (clean baseline)
Step 1:  Define fiber_backend.w interface                  (permanent abstraction)
Step 2:  Wrap current backend behind interface             (fiber_backend_current.w)
Step 3:  Rewire scheduler to use backend interface         (rt/fiber_runtime.w)
Step 4:  Verify no behavior change                         (full async test suite)
Step 5:  Migrate minicoro.h to With                        (with migrate)
Step 6:  Verify standalone minicoro behavior               (behav_minicoro_basic.w)
Step 7:  Implement minicoro backend                        (fiber_backend_minicoro.w)
Step 8:  Dual-backend test suite                           (--fiber-backend flag)
Step 9:  Performance comparison                            (benchmark)
Step 10: Verify on Darwin/aarch64, Linux/x86_64, Windows   (platform matrix)
Step 11: Remove old backend                                (cleanup)
Step 12: Verify no mco_* leakage                           (audit)
```

Each step is independently committable. Each step can be verified before proceeding. If any step fails, the previous step's state is a valid shipping configuration.

The critical ordering: the backend interface (steps 1-4) is introduced and validated while the current backend still works. minicoro plugs into a known-good seam rather than requiring simultaneous abstraction and migration.

---

## 9. Risks

| Risk | Mitigation |
|---|---|
| minicoro's `#ifdef` maze doesn't migrate cleanly | Keep assembly in separate `.s` files. Migrate only the C logic. Handle platform selection at link time. |
| Inline assembly not supported by `with migrate` | Extract assembly to standalone `.s` files, link as objects. This is the existing pattern. |
| minicoro's allocator doesn't match With's memory model | Use minicoro's custom allocator hooks to route through With's allocator. |
| Performance regression from indirection layer | The backend interface is a function call, not a vtable. Context switch cost dominates. Benchmark to verify. Accept small regressions for portability. |
| minicoro doesn't handle With's cancellation semantics | Cancellation is in the scheduler layer. minicoro only needs create/resume/yield/destroy. |
| Virtual memory allocator not available on all targets | Fall back to standard mmap. minicoro handles this via `MCO_USE_VMEM_ALLOCATOR` being optional. |
| Future minicoro updates | The migrated code is a snapshot. Pin to a specific commit. Upstream changes require re-migration. |
| Blocking syscalls inside fibers | Unchanged by migration. minicoro provides coroutine switching, not async IO. |
| Windows fiber conversion | `fiber_backend_init()` provides a clean place for `ConvertThreadToFiber` and thread-local state setup. |

---

## 10. Size Estimates

| Component | Estimated LOC | Notes |
|---|---|---|
| Async bug fixes (section 3) | ~200 | Five targeted fixes + panic/defer tests |
| `fiber_backend.w` interface | ~80 | Types, enum, function signatures, doc comments |
| `fiber_backend_current.w` | ~150 | Thin adapter over existing runtime |
| Scheduler rewiring | ~100 (net change) | Replace direct calls with backend calls |
| minicoro migration output | ~3,000-5,000 | Depends on `#ifdef` expansion |
| `fiber_backend_minicoro.w` | ~200 | Handle mapping, state mapping, debug assertions |
| Tests | ~400 | Standalone minicoro + backend comparison + panic/defer + destroy-while-suspended |
| **Total new hand-written code** | **~1,100** | Plus ~3-5K auto-migrated |

---

## 11. Success Criteria

The migration is complete when:

1. All existing async tests pass on the minicoro backend.
2. The five pre-existing async bugs are fixed and tested.
3. Panic/defer edge cases are tested.
4. Destroy-while-suspended test passes on both backends.
5. Darwin/aarch64, Linux/x86_64, and Windows/x86_64 all pass.
6. No `mco_*` symbol appears outside `rt/minicoro.w`, `rt/fiber_backend_minicoro.w`, and backend tests.
7. `make build && make fixpoint && make test` all pass.
8. The old backend is removed.
9. The backend interface (`fiber_backend.w`) remains as a permanent abstraction.
10. Context switch performance is comparable to the old backend, or any regression is understood and accepted.