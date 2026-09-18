# 003 — Suspension and cancellation

Status: **Evidence-bounded audit pass complete; no module marked complete**  
Inventory snapshot: `31f77937abad3bc6573df3b71a0c99b605d6ea8e`  
Executable evidence provenance: **stage1 is repository-internally bound to the
current HEAD inputs and recorded seed; see [Audit 009](../009-build-platform-harness-spec/audit.md)**  
Audit target: overview §4

## Verdict

Suspension and cancellation are not represented as one control-flow/effect
protocol. Direct `Task.await` has a dedicated cancellation protocol, but ordinary
calls, `select await`, channels, synchronization waits, Sema effect checking, and
post-MIR effect checking each reconstruct only part of it. The result is one
confirmed invalid free (#916), two independently confirmed cancellation hangs,
and two confirmed `no_suspend` false negatives.

The findings cluster at two duplicated semantic seams rather than in the task
combinators themselves:

1. MIR has no explicit cancellation/alternate-completion edge for calls that may
   suspend. A cancelled callee can return without a value, while every ordinary
   caller proceeds through the value-producing successor.
2. “May suspend” is re-derived from AST shape, a hand-maintained method list, and
   a second closed MIR-intrinsic list. Callable values and library wrappers fall
   between those classifiers.

## Scope and source authorities

Modules inspected:

- [`src/MirLower.w`](../../../src/MirLower.w) — direct await, tuple await,
  ordinary call families, `select await`, task drops, and cleanup joins.
- [`src/CodegenDispatch.w`](../../../src/CodegenDispatch.w) — await and select
  intrinsic emission and result-buffer ownership.
- [`src/SemaCheck.w`](../../../src/SemaCheck.w) — AST `may_suspend` recursion,
  callable checks, and the synchronization-method allowlist.
- [`src/MirSuspendCheck.w`](../../../src/MirSuspendCheck.w) — post-MIR yield set,
  direct-callee fixpoint, and `no_suspend` checking.
- [`src/compiler/Compilation.w`](../../../src/compiler/Compilation.w) — invocation
  of the post-MIR suspend check.
- [`rt/fiber_runtime.w`](../../../rt/fiber_runtime.w) — await/select loops,
  cancellation flags, completed-task status, panic handling, and Darwin/Windows
  backend operations.
- [`rt/rt_core.w`](../../../rt/rt_core.w) — async-scope cancellation, cleanup joins,
  and panic aggregation.
- [`rt/channel_runtime.w`](../../../rt/channel_runtime.w) — blocking send/receive.
- [`rt/fiber_stubs.w`](../../../rt/fiber_stubs.w) — non-async fallback surface.
- [`lib/std/task.w`](../../../lib/std/task.w) — task combinators and explicit
  cancellation points.
- [`lib/std/sync.w`](../../../lib/std/sync.w) — mutex, rwlock, once, condvar, and
  barrier wait loops.
- Existing cancellation, select, scope-panic, cleanup-join, allocator, and
  `no_suspend` fixtures under [`test/`](../../../test/).

The codebase graph did not expose the With functions needed for call-path
discovery, and the first broad Tilth queries were insufficient. Exact-text/source
fallback was therefore used for the inventory; Tilth was then used to inspect
bounded source sections.

## Protocol inventory

### Direct await

`lower_single_await` at `src/MirLower.w:7848-7952` is the only complete-looking
MIR cancellation protocol:

1. `FIBER_AWAIT` writes a result place (`7851-7865`).
2. `FIBER_IS_CANCELLED` tests cancellation of the awaiting fiber (`7867-7889`).
3. Self-cancellation cancels and cleanup-joins the child (`7891-7905`).
4. `FIBER_WAS_CANCELLED_RETURN` tests alternate completion of the child
   (`7907-7930`).
5. Either cancellation path marks the current return as cancelled, flushes
   pending resets, emits defers and drops, and returns (`7932-7948`).
6. Only the normal block exposes the result operand (`7950-7952`).

Tuple await lowers every element through this helper at
`src/MirLower.w:13495-13527`; it does not introduce a second protocol.
`lower_cleanup_await` at `7954-7967` deliberately drains a task without
propagating child cancellation. Task-drop cleanup and `join_cleanup` use this
non-interruptible drain, which is necessary to reclaim owned task results.

### Ordinary and dynamic calls

All five inspected value-returning call families emit `TK_CALL`, switch directly
to one successor, register the result temporary, then copy or move it:

- `lower_call`, `src/MirLower.w:8797-8863`;
- `lower_call_redirected`, `8866-8894`;
- `lower_call_with_arg_nodes_recv`, `8906-8941`;
- `lower_resolved_call_with_operand_args_contract`, `12286-12322`;
- `lower_call_with_receiver_operand`, `12324-12346`.

None has a cancellation successor or tests whether the callee produced a value.
That includes direct functions, redirected callable values, methods, generic
specializations, and receiver-operand paths.

### Select

`select await` uses a separate, incomplete protocol at
`src/MirLower.w:13631-13742`. It calls `FIBER_SELECT`/`_BIASED` and immediately
switches on a winner (`13650-13681`). Each winning arm then performs a raw
`FIBER_AWAIT`, immediately copies its result into the arm binding
(`13690-13714`), and only afterward cancels and cleanup-joins losers
(`13716-13731`). It never checks current cancellation or the winner's
cancelled-return flag.

The runtime loop in `with_fiber_select_mode`, `rt/fiber_runtime.w:178-191`,
repeatedly checks readiness and otherwise calls `with_fiber_yield()` at
`185-186`. The loop has no current-cancellation check.
`src/CodegenDispatch.w:10182-10241` emits this call and winner branch without
adding one.

### Runtime wait loops

`with_fiber_await`, `rt/fiber_runtime.w:196-228`, checks current cancellation
before yielding and records whether the awaited child made a cancelled return.
`with_fiber_cleanup_await`, `230-258`, intentionally ignores current
cancellation while draining.

The following ordinary blocking loops yield but never inspect current
cancellation:

- select: `rt/fiber_runtime.w:178-191`;
- bounded channel send: `rt/channel_runtime.w:172-180`;
- empty channel receive: `rt/channel_runtime.w:199-204`;
- mutex acquisition: `lib/std/sync.w:115-118`;
- `Mutex.set`: `203-204`;
- rwlock read/write acquisition: `237-255`, `304-308`;
- `Once.call_once` contention: `329-349`;
- condvar/barrier waits, which use the same `sync_wait_for_progress` helper.

`sync_wait_for_progress`, `lib/std/sync.w:108-113`, only yields or advances the
runtime. `channel_block_until_progress` has the same shape. Cancellation of a
task parked in one of these loops therefore cannot reach its generated cleanup
path unless some unrelated state change makes the loop return first.

### May-suspend classifiers

There are two competing classifiers:

- `src/SemaCheck.w:4189-4236` recursively identifies suspending AST forms and
  consults `method_may_suspend_current_fiber`.
- `method_may_suspend_current_fiber`, `src/SemaCheck.w:19211-19236`, hardcodes
  channel, synchronization, and cleanup-join method names.
- `src/MirSuspendCheck.w:261-278` separately defines the closed set of yielding
  MIR intrinsics.
- Its interprocedural fixpoint at `319-349` follows only callees encoded as an
  `OK_CONSTANT` whose constant kind is `CK_FN` (`280-290`). Callable parameters,
  closure values, trait/dynamic dispatch, and unresolved/external wrappers have
  no callee summary and are treated as non-suspending (`351-360`).

The pre-MIR `no_suspend` guard hooks defer to the post-MIR analysis; the Sema
walker is also used for selected direct-call/callback checks. There is no
persisted `may_suspend` fact on callable types or one authoritative effect
summary consumed by both layers.

### Cancellation flags, panic, and platforms

`with_runtime_request_cancel` sets a runtime cancellation flag; the Darwin
backend does so under the scheduler lock (`rt/fiber_runtime.w:894-907`) and the
Windows backend has the parallel operation (`678-683`). Current-cancel and
cancelled-return getters/setters are structurally mirrored on both backends.
The common select/channel/synchronization loops simply do not consume that
flag, so the missing behavior is platform-independent at the source boundary.
Only the active host was executed; Windows behavior was not run.

`last_await_fiber_id` and `last_await_cancelled_return` are file-global runtime
cache variables (`rt/fiber_runtime.w:46-47`). Their cross-thread safety was not
proved in this bounded pass.

Panic behavior is asymmetric. A direct `with_fiber_await` takes the child's
completion and calls `with_process_exit(134)` immediately for a panicked child
(`205-210`), before the awaiting function can run its MIR cleanup. Async-scope
cleanup in `rt/rt_core.w:3838-3894` instead records the first panic, cancels and
joins all siblings, frees their result buffers, then exits 134. The source
behavior is confirmed; whether direct-await panic must run caller defers is not
specified clearly enough to label this a defect without a maintainer ruling.

## Confirmed findings

### SUSP-001 — Cancelled may-suspend calls consume an unwritten return slot

Verdict: **Confirmed**  
Candidate severity: **Critical** — reachable invalid free and uninitialized
value consumption in ordinary production code.  
Blast radius: **Every ordinary call path whose callee may return via
cancellation**, not only `std.task` combinators.  
Confidence: **High**  
Issue relationship: **Existing issue #916**; also the producer for
[`VAL-001`](../001-validator-trustworthiness/audit.md), where `--validate-all`
accepts the bad return state.

Executable evidence:

```text
./out/bootstrap/bin/with-stage1 check \
  test/spec/spec_ss14_11_await_combinator_cancel_joins.w --validate-all
validate-all: ok

./out/bootstrap/bin/with-stage1 run \
  test/spec/spec_ss14_11_await_combinator_cancel_joins.w \
  --debug-alloc --debug-alloc-filter=non-root
invalid free addr=<address> origin=drop#struct __drop_struct_94
panic: invalid free: pointer is not an allocated payload start
```

The fixture covers five task combinators. LLDB resolves the invalid free to the
fixture's cancelled call result at line 25 and the allocator ownership check at
`rt/rt_core.w:1251-1258`.

Negative control: a parent cancelled while directly awaiting an infinite child
through `.await` completed, printed `single-ok`, and reported
`debug-alloc: leak count=0`. This distinguishes the complete direct-await
protocol from the ordinary-call failure.

Exact root cause: `lower_single_await` turns cancellation into
`FIBER_SET_CANCELLED_RETURN` followed by an ordinary `TK_RETURN` without writing
the function return place (`src/MirLower.w:7932-7948`). Every ordinary call
lowerer has exactly one successor and unconditionally copies/moves its result;
for example `lower_call` does so at `8857-8863`. MIR contains no outcome that
means “callee returned by cancellation and did not produce a value.” The caller
therefore treats stale/uninitialized storage as an owned value and may drop it.

Five Whys:

1. The allocator rejects a free because the caller drops a garbage result.
2. The result is garbage because the cancelled callee did not initialize it.
3. The caller consumes it because `TK_CALL` has only a value-producing successor.
4. Cancellation is encoded as an ordinary return plus side-channel runtime flag.
5. Call completion and result initialization are not modeled as one MIR/ABI
   invariant shared by direct await, ordinary calls, validation, and codegen.

Proper repair boundary: introduce an explicit call outcome/edge for cancellation
or an equivalent typed completion object in MIR and the call ABI. All call
lowerers, validators, codegen, task-result ownership, and effect summaries must
consume that one protocol. Special-casing the five combinators would leave every
other may-suspend call unsound.

### SUSP-002 — Cancelling a task blocked in `select await` cannot complete

Verdict: **Confirmed, candidate unreported**  
Candidate severity: **High** — deterministic cleanup-join hang and leaked task
liveness.  
Blast radius: **Every unbiased or biased select whose alternatives remain
pending when its owner is cancelled.**  
Confidence: **High**  
Live tracker limitation: a final tracker sweep was not run in this bounded pass;
classify as candidate unreported until deduplicated.

Minimal reproduction:

```with
async fn tick() -> i32: 1
async fn forever(value: i32) -> i32:
    while true:
        let _ = tick().await
    value

async fn parent() -> i32:
    let left = forever(1)
    let right = forever(2)
    select await:
        value = left => ()
        value = right => ()
    0

fn main:
    let task = parent()
    // Drive until parent and both children are live.
    task.cancel()
    task.join_cleanup()
```

The complete probe (including the liveness drive) passed `check --validate-all`
but timed out after four seconds under the debug allocator without reaching
`select-ok`.

Debugger evidence: a breakpoint in `with_runtime_request_cancel` observed the
parent fiber id `0x400` being marked at `rt/fiber_runtime.w:895-900`. After that
request returned, LLDB stopped the same execution at
`with_fiber_select_mode`, line 185, reached from the selected parent's source
line 16. That line's only branch is “in a fiber, therefore yield”; it never tests
the cancellation flag just set.

Exact root cause: `with_fiber_select_mode` loops at `rt/fiber_runtime.w:178-191`
until one task is ready. Its pending branch at `185-186` unconditionally yields.
The MIR select lowering cannot recover because it receives no return until a
winner exists, and it has no self-cancellation branch after the select call
anyway (`src/MirLower.w:13650-13681`).

Proper repair boundary: select must participate in the same explicit
completion/cancellation protocol as await. A cancelled selection must stop
waiting, cancel and cleanup-join every owned alternative exactly once, run the
parent's cleanup, and return as cancelled without exposing a winner/result.

### SUSP-003 — Cancelling a task blocked in channel receive cannot complete

Verdict: **Confirmed for receive; send and synchronization waits are
source-equivalent candidates**  
Candidate severity: **High** — deterministic cleanup-join hang.  
Blast radius: **Empty receives whose send side remains open; structurally, full
bounded sends and all waits using `sync_wait_for_progress`.**  
Confidence: **High for receive, medium-high for unexecuted sibling loops**  
Issue status: candidate unreported pending live deduplication.

Minimal reproduction:

```with
use std.channel

async fn blocked(rx: Receiver[i32]) -> i32:
    let _ = rx.recv()
    0

fn main:
    let (tx, rx) = chan[i32](1)
    let task = blocked(rx)
    // Drive until task is live and blocked with tx still open.
    task.cancel()
    task.join_cleanup()
```

The full liveness-driven probe passed `check --validate-all`, then timed out
after four seconds under the debug allocator without reaching `channel-ok`.

Exact root cause: `with_channel_recv` loops while count is zero at
`rt/channel_runtime.w:199-204`; after `channel_block_until_progress()` it tests
only the non-fiber/no-live-fibers termination case. It never consumes current
cancellation, so `join_cleanup` waits forever. The send loop at `172-180` has the
same missing condition. The synchronization wait helper at
`lib/std/sync.w:108-113` likewise yields without testing cancellation.

Proper repair boundary: define a single cancellation-aware scheduler wait
primitive and require all interruptible wait loops to use it. Cleanup waits must
remain explicitly non-interruptible. Channel and synchronization APIs also need
a defined cancellation result so no payload/guard is fabricated on interruption.

### SUSP-004 — `no_suspend` accepts a may-suspend callable passed indirectly

Verdict: **Confirmed, candidate unreported**  
Candidate severity: **High** — invalidates the guard intended to keep references
and protected state from crossing a suspension.  
Blast radius: **Callable parameters, closure values, and likely trait/dynamic
dispatch without a statically encoded `CK_FN` callee.**  
Confidence: **High for callable parameters; medium for unexecuted dynamic forms**

Minimal reproduction:

```with
async fn work() -> i32: 42
fn invoke(cb: fn() -> i32) -> i32: cb()

fn main:
    let cb = () =>
        let task = work()
        task.await
    no_suspend:
        let value = invoke(cb)
```

`check --validate-all` returned `validate-all: ok`; execution completed with
`debug-alloc: leak count=0`. The existing direct-call negative control
`err_no_suspend_may_suspend_callable_value.w` rejects the same suspending closure
with E0702. The indirect wrapper is the differentiator.

Exact root cause: `suspend_callee_sym`, `src/MirSuspendCheck.w:280-290`, returns
no callee for a callable operand unless it is an `OK_CONSTANT`/`CK_FN`.
`suspend_term_may_suspend` treats that absence as non-suspending at `351-360`.
No callable type carries a `may_suspend` effect that could close the gap.

Proper repair boundary: make suspension an authoritative function/callable effect
computed once and preserved through parameters, closures, generic substitution,
trait objects, defaults, and FFI callback types. Both Sema and MIR checking must
read it rather than infer safety from missing callee identity.

### SUSP-005 — `no_suspend` accepts a transitive synchronization wait

Verdict: **Confirmed, candidate unreported**  
Candidate severity: **High** — the same guard false negative through an ordinary
named wrapper.  
Blast radius: **Any wrapper around mutex/rwlock/once/condvar/barrier waits whose
yield occurs behind an extern/runtime call not seeded in the MIR effect graph.**  
Confidence: **High for the mutex wrapper; medium-high for sibling primitives**

Minimal reproduction:

```with
use std.sync
fn acquire(lock: &Mutex[i64]) -> MutexGuard[i64]: lock.enter()

fn main:
    let lock = Mutex[i64].new(1 as i64)
    no_suspend:
        let guard = acquire(&lock)
```

The wrapper passed `check --validate-all` and ran without allocator findings. An
existing direct `lock.enter()` negative test rejects E0702.

Exact root cause: Sema's method-name allowlist recognizes `Mutex.enter` only at
the lexical call site. The post-MIR fixpoint can propagate only from its closed
intrinsic seed set (`src/MirSuspendCheck.w:261-278`), but `std.sync` ultimately
yields through the raw runtime `with_fiber_yield` call and therefore provides no
seed. `acquire` is consequently summarized as non-suspending.

Proper repair boundary: remove the method-name classifier. Runtime/stdlib
primitives need declared, checked suspension effects; ordinary wrappers must
inherit them in the same effect graph used for callable values.

## High-confidence candidates and unresolved questions

These were not promoted to confirmed defects because the bounded pass did not
finish an independent executable isolation or because the contract is unclear:

- **Cancelled select winner result.** `select await` awaits its winner through a
  raw `FIBER_AWAIT` then binds the result without
  `FIBER_WAS_CANCELLED_RETURN` (`src/MirLower.w:13690-13714`). A task that becomes
  ready by cancelled completion can therefore expose an unwritten result instead
  of propagating cancellation. This is the select analogue of SUSP-001.
- **Direct child-cancel result load ordering.** Await codegen checks only current
  cancellation before loading/freeing the child result
  (`src/CodegenDispatch.w:10106-10174`); MIR checks the child's
  cancelled-return flag afterward. A child-cancelled return may therefore cause
  an uninitialized physical load even though the MIR result is not later used.
- **Global last-await cache.** The file-global `last_await_*` cache may race under
  concurrent worker threads. Thread-locality and the completed-record fallback
  need debugger-backed verification on every threaded backend.
- **Panic cleanup contract.** Direct await exits the process before caller
  cleanup, while async scope drains siblings first. The required defer/resource
  semantics on panic need a maintainer ruling before choosing a fix.
- **Cancellation races.** No interleaving matrix was executed for cancellation
  immediately before completion, after runtime completion but before the MIR
  check, or concurrent cancel calls. These remain necessary even after the
  single-thread control-flow defects are repaired.

## Regression matrix

The repair is not demonstrated by making the #916 fixture green. At minimum the
following matrix must pass with `--validate-all`, the native debug allocator, and
timeout/liveness assertions:

| Surface | Outcomes | Result shapes | Composition |
|---|---|---|---|
| Direct await | normal, self-cancel, child-cancel, panic | `Unit`, `Copy`, owned scalar, aggregate/drop type | direct, tuple, nested |
| Ordinary call | normal, callee-cancel, caller-cancel while callee blocked | same four shapes, ignored result | free fn, method, generic, recursive wrapper |
| Dynamic call | same cancellation outcomes | same four shapes | closure value, callable parameter, trait/dynamic dispatch, default callback |
| Select | winner normal/cancelled/panicked; parent cancelled before/after winner | Copy and owned winner values | biased/unbiased, two/many arms, owned/borrowed task handles |
| Channel | send/recv ready, closed, blocked, cancelled, competing wake/cancel | Copy and owned payload | bounded/unbounded, last sender/receiver drop |
| Synchronization | uncontended, contended, cancelled, wake/cancel race | every guard/value ownership mode | mutex, rwlock, once, condvar, barrier, one wrapper and two wrappers |
| Cleanup | ordinary drop, explicit `join_cleanup`, async-scope exit, nested cancellation | zero/one/many child results | child ignores cancel temporarily; sibling panic |
| Platform | all preceding scheduler cases | same layouts | Darwin, Linux, Windows; single and worker-thread schedulers |

Required negative controls:

- direct `no_suspend` rejection and one/two-wrapper rejection;
- callable passed through one/two parameters and trait/dynamic boundaries;
- a deliberately malformed cancelled call result rejected by every advertised
  MIR validator;
- liveness returns to baseline after each cancellation;
- exactly-once drop counts and zero allocator leaks/invalid frees;
- panic exit code 134 only after the contractually required cleanup.

## Issue relationships

- **#916** is SUSP-001's existing user-visible manifestation, but its repair
  boundary is call completion, not the five `std.task` combinators.
- **VAL-001** is the verification twin: validation encodes the same false
  “`TK_CALL` always initializes its destination” assumption.
- **SUSP-002 through SUSP-005** are candidate unreported issues. Live tracker
  deduplication remains explicit follow-up; no issues were filed during this
  report-only audit.
- Select-result cancellation is probably another manifestation of the SUSP-001
  protocol gap, while channel/synchronization hangs are runtime consumers of the
  missing cancellation-aware wait abstraction.

## Revision applicability and limitations

[Audit 009](../009-build-platform-harness-spec/audit.md) reconciles the stage1
provenance: the current cache ledger and hashed `seed-input.json` extra-output
record bind the stage1 fingerprint to the current HEAD input contents and
recorded seed, and the read-only `build --explain stage1 :stage1` query reported
that artifact fresh. The placeholder version stamp is an intentional sentinel,
not evidence of an unknown source revision. This is the strongest available
repository-internal source/artifact binding without rebuilding; an independent
current-source rebuild and current stage2/stage3 fixpoint remain stronger but
unrun evidence.

This pass deliberately did not run a full build, full suite, Windows backend,
worker-thread race campaign, live tracker sweep, or every answer in the
regression matrix. It used focused stage1 checks/runs, allocator verdicts, and an
LLDB control-flow proof. These limitations do not weaken the five confirmed
findings; they prevent module-completion claims and keep the listed candidates
separate from confirmed defects.

## Module-completion impact

No module is marked complete. The inspected compiler/runtime/stdlib modules all
overlap additional audit targets, especially call/return correctness, validator
trustworthiness, closure/dynamic-call semantics, cleanup control flow, runtime
lifecycle, platform agreement, and specification coverage. Target §4 has a
bounded evidence report, but completion requires the live issue sweep, an
independent current-source rebuild and fixpoint, all platform backends, and the
full regression matrix above.
