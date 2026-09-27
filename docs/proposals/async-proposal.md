# Fiber Backend: minicoro Convergence Port

Converge the existing fiber backend onto minicoro's semantics via a
disciplined hand-port, behind a permanent backend interface, validated by
dual-backend testing. The scheduler, scope tracking, cancellation,
channels, and all async language constructs stay owned by With. minicoro
is the trusted reference for the context-switch substrate — not a
dependency, not a migration target.

Supersedes the earlier "Fiber Backend Migration: minicoro" revision of
this document, which prescribed `with migrate` and described a
Darwin-only backend that no longer exists.

---

## 1. Motivation: trust, made concrete

The fiber substrate is the most safety-critical, least testable code in
the runtime. A context switch that saves one register too few, or skips
one piece of OS bookkeeping, works in every happy-path test and corrupts
mysteriously under load. Rolling our own is an act of unwarranted
self-confidence; the responsible posture is to converge on an
implementation whose failure modes a decade of production use has
already found and documented. That implementation is minicoro
(`.reference/minicoro/minicoro.h`, ~2,000 lines, MIT-0, battle-tested by
Nelua and others).

This is not deference. minicoro is valuable because its defects are
*known*, not because it has none:

**Demonstrated gap in our backend (found by comparison, 2026-08-31):**
minicoro's Windows x64 switch swaps four TEB fields on every context
switch — `gs:[0x30]` → TEB, then `0x8` StackBase, `0x10` StackLimit,
`0x1478` DeallocationStack, `0x20` FiberData. Our
`runtime/fiber_asm_windows_x86_64.s` swaps none of them, so while a
fiber runs, Windows believes the thread is still on its OS stack.
Everything that consults stack bounds is wrong on a fiber: `__chkstk`
probes (every function with a frame over one page), SEH dispatch, OS
callbacks. Our register save set is correct (including XMM6–15); the OS
bookkeeping is the hole. The red Windows test lanes (#797–#811, #798's
0xC0000005, #874's flakiness) are at minimum consistent with this class.

**Documented upstream defects we fix in the port** (upstream is
effectively frozen; these have sat open for years):

| Upstream | Lesson for the port |
|---|---|
| issue #27 — OpenBSD `not MAP_STACK` crash | Same class as the TEB gap: the OS tracks what memory is a legitimate stack. Generalize as **stack registration**, a named backend obligation (§5.2), not per-OS hacks. |
| issue #31 — emscripten backend globals not `thread_local` | No backend global may be shared across threads: thread-local or scheduler-owned, enforced by review rule. |
| issue #11 — red-zone bytes reserved at the wrong end of the stack | Harmless upstream, but wrong reasoning encoded. Callers of resume/yield are non-leaf; drop the reservation, note why. A warning against porting logic without comprehension. |
| PR #30 (unmerged) — ASAN `__sanitizer_{start,finish}_switch_fiber` mispaired | When we add sanitizer hooks, adopt the corrected pairing, not the shipped code. |
| PR #29 (unmerged) + issue #22 — Thumb/Cortex-M asm hygiene | Adopt the asm conventions (unified syntax, explicit return sequences) in our `.s` templates now; embedded targets later inherit correctness. |

**README caveats that a C library may disclaim but a language runtime
must fix** — each becomes a named deviation with pinned fixtures:

1. *"`mco_coro` is not thread safe."* With schedules fibers under thread
   scopes; the port owns an explicit synchronization contract
   (single-owner resume with fenced handoff, or a lock — per the
   scheduler's design).
2. *"Avoid `thread_local` inside coroutine code"* (compilers cache TLS
   pointers across suspension; invalid if the fiber resumes on another
   thread). Either cross-thread resume is made safe (a codegen contract:
   no cached TLS across suspension points) or impossible (fibers pinned
   to threads). A decision, recorded in the port map — not a user
   warning.
3. *"Stack overflow … behavior is undefined."* Unacceptable under
   "exactly as safe as Rust." Our existing guard pages + SIGSEGV handler
   with per-fiber attribution are *better than upstream* — a kept
   deviation.
4. *"With RAII you must resume the coroutine until it dies to run
   destructors."* In With terms: a dropped/cancelled Task must unwind —
   defers and drops run (Higher RAII). minicoro does not unwind; our
   cancellation path must, pinned by drop-exactly-once fixtures at every
   suspension point. The panic-across-fiber-boundary analogue is pinned
   alongside.

**Why a hand-port, not `with migrate`:** the trust-critical 40% of
minicoro cannot go through the migrator — the Win64 switch is a
machine-code byte array, the other switches are inline asm (our `.s`
exception applies regardless), the vmem allocator is syscalls. What
migrate *can* translate is the glue least worth translating, and its
output is modeled C — wrong dialect for a permanent `rt/` foundation. At
2,000 lines, porting with full comprehension transfers more trust than
mechanical translation, and it is where upstream's four known defects
get fixed rather than faithfully reproduced.

---

## 2. What exists today

The current backend (landed May–June 2026 with the Windows bootstrap
arc) already covers three OSes:

- `runtime/fiber_asm_{aarch64,linux_aarch64,linux_x86_64,windows_aarch64,windows_x86_64,x86_64}.s`
  (~540 lines total) — register save sets verified correct per ABI.
- `rt/fiber_core_darwin.w` (~1,090 lines): mmap stacks, `PROT_NONE`
  guard pages, SIGSEGV overflow handler with fiber attribution, stack
  pooling.
- `rt/fiber_core_windows.w` (~814 lines): VirtualAlloc stacks, guard
  protection, vectored handler.
- `rt/fiber_runtime.w` (~320 lines): scheduler, ready queues, scope
  tracking, cancellation.

The port is therefore a **convergence**, not a rewrite: walk minicoro
function-by-function, converge the existing code onto its semantics,
record every delta. Working guard/pool/attribution code is kept, as
documented deviations where we exceed upstream.

---

## 3. Architecture

### 3.1 Layering (unchanged in spirit)

```
async fn / await / select await       (language)
        |
  MIR intrinsics                       (compiler)
        |
  With scheduler + task runtime        (rt/fiber_runtime.w)
  ready queues, scope tracking, cancellation
        |
  fiber backend interface              (rt/fiber_backend.w)  ← permanent seam
        |
  converged backend                    (rt/fiber_core_*.w + runtime/*.s)
  = verified minicoro port with documented deviations
```

The backend interface is permanent: insurance for WASM targets, debug
backends, sanitizer builds, the Win32-Fiber option, and any future
substrate.

### 3.2 What does not change

`Task[T]`, `await`/`select await` lowering, cancellation propagation,
`async scope`, channels, result buffers, trampolines, `async fn`
signature transformation — all above the seam, all untouched. Blocking
syscalls still block the OS thread; IO reactors remain out of scope.

---

## 4. Prerequisites (§3 of the previous revision) — status audit

Verified 2026-08-31:

| Item | Status |
|---|---|
| 3.1 scope-track growth UAF | **Fixed** — `with_scope_track` (rt/rt_core.w:3801) uses a stable handle with in-place growth, the exact prescribed fix. |
| 3.5 `await_first` awaits index 0 | **Fixed** — winner chosen by `with_runtime_fiber_completion_sequence`. |
| 3.2 select-await arm typing | Verify against current MirLower before the port; fix if live. |
| 3.3 select-await no-ready path | Same. |
| 3.4 await result type fallback chain | Same. |
| 3.6 panic/defer edge-case matrix | **Owed.** Write it first — it doubles as the dual-backend acceptance suite (panic before/after first yield; normal return with active defers; cancel inside nested defers; await of panicked task; unhandled-panic report). |

---

## 5. Phase 1: Backend interface

### 5.1 Interface

`rt/fiber_backend.w`, in current With (the earlier draft's `distinct`
types await the #666 campaign; return types are `Unit`):

```with
type FiberHandle = *mut i8          // becomes distinct when #666 lands

enum FiberState: i32:
    Suspended = 0
    Running = 1
    Dead = 2

fn fiber_backend_init() -> i32          // platform setup; Windows fiber/TEB prep
fn fiber_backend_shutdown() -> i32
fn fiber_backend_create(entry: fn(*mut i8) -> Unit, user_data: *mut i8, stack_size: i64) -> FiberHandle
fn fiber_backend_resume(handle: FiberHandle) -> i32
fn fiber_backend_yield() -> i32
fn fiber_backend_destroy(handle: FiberHandle) -> i32
fn fiber_backend_running() -> FiberHandle
fn fiber_backend_is_inside_fiber() -> bool
fn fiber_backend_user_data(handle: FiberHandle) -> *mut i8
fn fiber_backend_state(handle: FiberHandle) -> FiberState
```

Ownership and assertion rules as in the earlier draft: user_data is
scheduler-owned; yield-from-main and resume-non-suspended panic in debug
builds.

### 5.2 Stack registration — a named contract clause

New, and the generalization upstream never made: **a backend owns the
OS's knowledge of its stacks.** Concretely:

- `fiber_backend_create` performs any OS-level stack legitimization the
  platform requires (Windows: record TEB bounds in the context;
  OpenBSD-class platforms: `MAP_STACK` mapping; others: none).
- The switch path hands stack identity to the OS on every switch
  (Windows: the four-field TEB swap; others: no-op).

This turns the Windows TEB dance and #27's `MAP_STACK` from unrelated
platform hacks into one auditable obligation with one test shape per
platform ("large-frame call on a fiber succeeds"; "SEH/signal dispatch
on a fiber succeeds").

### 5.3 Wrap, rewire, verify

As in the earlier draft: wrap the *current* (now multi-platform) backend
behind the interface, rewire `rt/fiber_runtime.w` to backend calls only,
run the full async corpus, require zero behavior change before any port
work begins.

---

## 6. Phase 2: The convergence port

### 6.1 Two rules for two layers

- **Transcription** (no creativity permitted): the per-ABI switch
  sequences, including the TEB swap. Instruction-for-instruction against
  minicoro's published sequences, offset provenance in `.s` comments,
  diffable by eye. PR #29's asm conventions adopted.
- **Comprehension port** (native With, no mechanical translation): the
  lifecycle state machine (create/resume/yield/destroy/status, storage
  handoff), allocator integration, per-thread backend state.

### 6.2 The port map is a deliverable

`docs/fiber-minicoro-port.md`: every With function ↔ its minicoro
counterpart ↔ every deviation, with rationale. The deviations ledger at
minimum:

1–4. The four README caveats converted to guarantees (§1).
5. #11: red-zone reservation dropped (non-leaf callers), with reasoning.
6. #27-class: stack registration as an interface obligation (§5.2).
7. #31-class: no shared backend globals — thread-local or
   scheduler-owned only.
8. PR #30: sanitizer switch-fiber pairing per the corrected patch.
9. Kept superiorities: guard pages + per-fiber overflow attribution,
   stack pooling.
10. Windows backend choice (see §6.4).

This document is what makes the result "a verified port with documented
deltas" rather than "our own thing, inspired by."

### 6.3 Validation assets

- minicoro's testsuite (`tests/testsuite.c`) ported to With behavior
  tests.
- The C original kept runnable as an **external differential oracle** on
  darwin/linux (never linked into With; same scenarios, compared
  observable behavior).
- The 3.6 panic/defer matrix and drop-exactly-once cancellation fixtures
  under `--debug-alloc`.

### 6.4 Windows backend decision (made during the port, recorded in the map)

minicoro's own default under MSVC is the **Win32 Fiber API**
(ConvertThreadToFiber/SwitchToFiber) — the OS maintains TEB itself, the
maximally trusted primitive on the platform where we are weakest. The
port evaluates: raw-asm-with-TEB-swap vs Win32 Fibers per Windows arch.
windows-aarch64 has no upstream raw-asm precedent to transcribe, which
argues for OS fibers there regardless.

---

## 7. Phase 3: Dual-backend testing

As in the earlier draft, now with the port as the second backend:

- `--fiber-backend=current | ported` build selection at link time.
- Full async/channel/scope/panic corpus on both; destroy-while-suspended
  on both; §4's fixture matrix on both.
- Acceptance: everything passing on `current` passes on `ported`;
  the deviation fixtures (which `current` may fail — e.g. TEB tests
  before the immediate slice lands) pass on `ported`.
- Context-switch benchmark; a small regression is acceptable for
  correctness, any large one must be understood.

## 8. Phase 4: Promote and clean up

- Flip the default to the ported backend; keep `current` selectable for
  one release as the A/B harness; then remove it.
- The backend interface stays permanently.
- Containment audit (replaces the old `mco_` rule): port-internal names
  never leave `rt/fiber_*`; nothing minicoro-shaped appears in `lib/std/`,
  `src/`, public signatures, or diagnostics.

---

## 9. Immediate slice — independent of the campaign

**Transcribe the TEB swap into `runtime/fiber_asm_windows_x86_64.s`
now.** It is a live correctness hole with a trusted reference to copy
from, ~20 instructions, diffable against minicoro's published byte
sequence, and may un-redden several Windows lanes. It is also simply the
first transcription unit of §6.1, pulled forward. Pair it with the two
stack-registration tests (§5.2) for Windows.

---

## 10. Ordering

```
Slice:   TEB swap transcription + Windows stack tests      (days; live bug)
Step 0:  §4 audit — verify 3.2/3.3/3.4, write 3.6 matrix   (clean baseline)
Step 1:  fiber_backend.w interface (+ stack registration)  (permanent seam)
Step 2:  Wrap current backend; rewire scheduler            (no-change gate)
Step 3:  Port map skeleton + deviations ledger + fixtures  (fixtures FIRST)
Step 4:  Convergence port, function-by-function            (the campaign)
Step 5:  minicoro testsuite ported; C oracle lane          (validation)
Step 6:  Dual-backend matrix green                         (acceptance)
Step 7:  Windows backend decision recorded                 (§6.4)
Step 8:  Flip default; one release of A/B; remove current  (cleanup)
```

Every step independently committable; each prior state remains a valid
shipping configuration.

---

## 11. Risks

| Risk | Mitigation |
|---|---|
| Port infidelity (the hand-port version of migration bugs) | Transcription rule for the critical layer; port map review; ported testsuite; C oracle differential; dual-backend corpus. |
| Upstream divergence | Upstream is effectively frozen (open PRs/issues for years); we pin the referenced commit in the port map and consciously own the fork. |
| TEB swap transcription error | Byte-sequence diff against minicoro's published code; Windows stack-registration tests (`__chkstk` large-frame, SEH-on-fiber). |
| Cross-thread TLS hazard mishandled | Explicit decision (§1 caveat 2) with a pinned test either way; until decided, fibers stay thread-pinned. |
| Cancellation unwind gaps | Drop-exactly-once fixtures at every suspension point under `--debug-alloc`; the D32-era drop machinery already audits this class. |
| Win32 Fiber API costs (if chosen) | Behind the interface; benchmarked in §7; per-arch choice allowed. |

---

## 12. Success criteria

1. Port map complete: every backend function mapped, every deviation
   named with rationale and fixture.
2. The four README-caveat guarantees and four upstream-defect fixes each
   pinned by a passing test.
3. minicoro's ported testsuite green; C-oracle differential green on
   darwin/linux.
4. Full async corpus green on both backends; §4 fixture matrix green.
5. Windows stack-registration tests green (large-frame, SEH-on-fiber).
6. Darwin/aarch64 + Linux/x86_64 + Windows/x86_64 green.
7. `with build && with build :fixpoint && with build :test` green;
   drop-audit green (cancellation unwind touches drop scheduling).
8. Containment audit green; old backend removed after one A/B release.
