# Share-place (D5) — Historical Gap Record (Superseded)

> **SUPERSEDED (2026-07-23).** Do not treat these D5 gaps as current language
> requirements. Free functions use declared `&T` borrow / plain `T` consume
> modes. The tasks and remedies below are archaeology, not a backlog.
> Receiver-mode by-place behavior remains governed separately by D12. For D22,
> `docs/d22-Eric-Ruling.md` is canonical and every conflict here is false.

Historically tracked gaps in the share-place calling-convention implementation. Each has a
deterministic repro and `--dump-abi` evidence. Verify fixes with the
`/drop-audit` skill and `--dump-abi`, not by reasoning.

---

## G1 — extern `@[effect(consume)]` not applied to share-place classification — RESOLVED

**RESOLVED:** the classification was correct (`--dump-abi`: OWNED); the gap was
call-site enforcement — extern calls skipped `record_consume_call_site`. Fixed in
SemaCheck.w:12501 (enforce for extern params whose effect includes CONSUME/
ESCAPE_VALUE). Test un-skipped + migrated. The historical diagnosis below is kept
for reference.


**Repro:** `test/compile_errors/err_effect_extern_consume_marks_moved.w` (currently `//! skip:`).

```with
@[effect(handle: consume)]
extern "C" fn close_external(handle: Handle) -> Unit
fn main:
    let handle = Handle { id: 1 }
    unsafe { close_external(handle) }
    let _ = handle.id            // should be use-after-move; currently accepted
```

**Fact (`with check … --dump-abi`, after the drop-scope/move-self work landed):**
```
fn close_external  param[0] ty=… eff=[consume] value_ref_abi=0 -> OWNED
```
The classification is **correct** — the declared consume IS honored and the
param is OWNED. (An earlier note here recorded `eff=[none] -> SHARE-PLACE`; that
was a stale, pre-rebuild reading — `--dump-abi` corrected it.)

The bug is at the **call site**, and it is extern-specific:
- a regular consuming call — `fn sink(h: Handle) -> Handle: h; … sink(handle)` —
  correctly errors "this parameter takes ownership … pass `move x`" and marks
  `handle` moved;
- the extern call `close_external(handle)` (with or without `unsafe`) produces
  **no** ownership error at all, so `handle.id` afterwards is not caught as
  use-after-move.

So extern calls skip the OWNED-param consume enforcement that regular calls run
(`record_consume_call_site` / `finalize_call_site_ownership`). The extern-call
path short-circuits before that recording — see the `extern_fn_names.contains`
branches in `SemaCheck.w` (~3552, ~4045) in the call-arg checking flow.

**Fix direction:** make extern-fn calls record a consume-call-site (or mark the
arg moved) for each OWNED (consume/escape_value) parameter, the same way regular
calls do. Then remove the skip; the test should produce `use of moved value` (or
a require-move) at `close_external(handle)`. Verify the classification stays
OWNED with `--dump-abi`.

---

## G2 — move-self receiver: Sema label vs MIR behavior divergence — RESOLVED

**RESOLVED:** `fn_param_uses_value_ref_abi` (SemaDecl.w) classified *any*
receiver-typed param as share-place, ignoring receiver mode. Now a `move self`
receiver returns 0 (OWNED) — `mut self` / `&self` / plain `self` stay share-place.
The move-self param's effect is also seeded with CONSUME (SemaCheck.w). `--dump-abi`
now shows `move self` as `eff=[consume] value_ref_abi=0 -> OWNED`, matching the
MIR's drop discipline (D6). Verified: drop-audit 0 fail, full suite green, fixpoint
holds. History below for reference.


`--dump-abi` reports a `move self` receiver as `value_ref_abi=1 -> SHARE-PLACE`
(because a read-only move-self body infers effect READ). The **behavior** is
correct — `lower_method_call` consumes the receiver at the call site and
`lower_fn_with_sig` drops it in the callee (verified: `/drop-audit` 0 fail) — but
the ABI *label* still says SHARE-PLACE while the drop discipline is OWNED. Per D6
(FnAbi single source of truth) the classification should match. A clean fix would
seed the move-self param's effect with `EFF_CONSUME` at the callee's body-check so
`assign_share_place_abi` classifies it OWNED, letting the caller-consume +
callee-drop fall out of the normal owned path instead of receiver-mode overrides.
Confirm any such change leaves `/drop-audit` at 0 fail and `--dump-abi` showing
`-> OWNED` for move-self.

---

## G3 — ephemeral Task double-frees when awaited through a share-place borrow — RESOLVED

**RESOLVED:** `result_buf` was freed by BOTH the value-await (FIBER_AWAIT) and the
Task drop (FIBER_CLEANUP_AWAIT). Fixed by threading an `await_owns` flag from
MirLower to codegen: a value-await frees the buffer only when this scope OWNS the
task (a temporary, or an owned local whose scheduled drop the await cancels) — a
borrowed param's owner-drop frees it instead. `await_task_owns_result` +
`local_has_scheduled_value_drop` (MirLower.w), threaded through `lower_single_await`
and the tuple-await / select-await FIBER_AWAIT emitters; codegen reads the flag
(CodegenDispatch.w). Verified with `--debug-alloc` across owned/temporary/tuple/
select/borrowed (all leak count=0). Test un-skipped. History below for reference.


**Repro:** `test/behavior/behav_ephemeral_task_consuming_callee.w` (currently `//! skip:`).

```with
fn consume_task(task: Task[i32]) -> i32:
    task.await                       // borrows `task` (share-place), drives it
fn main:
    let first = process(&value)
    assert(consume_task(first) == 42)  // asserts pass...
    // ... then panic: "invalid free" at main's scope exit
```

`.await` does not consume the task (§14.7 — the task stays observable), so a task
passed by share-place borrow into a callee that awaits it is still owned by the
caller and dropped at the caller's scope exit. But `await` has already reaped the
task's fiber/internal state, so the caller's Task drop frees it a second time →
double free. `spec_ss14_7` (await + observe in the SAME scope) is fine; the bug is
specifically await-through-a-borrow then caller-drop.

**Fact (`with run --debug-alloc`):**
```
debug-alloc: DOUBLE FREE addr=… size=16 origin=with_alloc first_drop=<untagged> second_drop=<untagged>
```
The 16-byte `with_alloc` block is the **async entry** `[fiber_id: i32, pad: i32,
result_buf: *mut u8]` (rt/rt_core.w:3507) backing a `Task[T]`
(`{ fiber_id, result_buf }`, lib/std/task.w:13). `await`-through-a-borrow
(`consume_task` borrows `first`, then `first.await`) drives the fiber and reaps
the frame, and the OWNER's scope-exit Task drop — `lower_cleanup_await`
(MirLower.w:6798), scheduled by `task_drop_kind_for_binding` (695) — reaps it a
SECOND time. `spec_ss14_7` (await + observe in the SAME scope, task owned there)
is fine; the double-free is specifically await-through-a-borrow then owner-drop.

**Fix direction:** either (a) `await` on a task the caller does NOT own (a
share-place borrow) must drive + read the result but NOT free `result_buf` /
reap the fiber — leave that to the owner's Task drop; or (b) make the Task
cleanup idempotent (a reaped/freed flag so the second `lower_cleanup_await` frees
nothing). NOT an `await`-consume workaround (reverted — violates §14.7).

**Next step (tooling):** the two free sites are `<untagged>` — name them at the
instruction level before editing runtime code. Run `tools/debug_drop.w` +
`tools/debug_drop_sites.lldb` on the repro (docs/debug-allocator.md) to get the
exact allocation site and both free call sites of the async entry, then decide
which free path to drop (the borrowed-await reap, vs the owner's Task drop).
Verify with `--debug-alloc` (no double free, leak count == 0) and that
`spec_ss14_7` and behav_ephemeral_task_consuming_callee both pass.
