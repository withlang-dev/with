# Primary verification — `src/MirSuspendCheck.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `58a418e2529b4c906d89ca5c3693e39ea85ea663c26df04793fd68685c276f47`
Source examined: all 874 lines (primary read 1-124, 124-168, 168-348,
348-480, 480-569, 569-874 — complete)

## Scope examined

The E0701/E0702 suspend checker: liveness dataflow (`suspend_gen_*`,
`:95-165`), may-suspend fixpoint over the call graph (`:313-360`),
guard-origin provenance (`suspend_prov_*`, `:415-570`), the report loop
(`suspend_check_body`, `:764-844`), no_suspend checking (`:846-864`), and
the yield-intrinsic closed set (`suspend_is_scheduler_yield_intrinsic`,
`:261-278`).

Applicable overview targets examined: 4 (suspension/cancellation), 13–14
(MIR validity), 23 (fail-loud — diagnostics, not defaults), 24 (duplication
between the liveness and provenance transfer functions).

## Behavioral matrix

Probes in `docs/audit/probes/mir_small/`, re-run by primary with seed stage1
`check` at 450733e5:

- `q1_agg_borrow_read.w` (borrow through tuple across await): ok, rc=0 —
  expected E0701. FALSE NEGATIVE, filed #999.
- `p5_derived_aggregate.w` (destructure + use after await): ok, rc=0 —
  same hole, second shape.
- `p1_guard_across_await.w` (direct guarded use across await): E0701, rc=1
  — positive control, guard works outside aggregates.

## SUSP-001 — aggregate provenance hole (filed #999)

Classification: **Confirmed soundness-guard false negative; reported as #999**
Severity: **High** — deterministic E0701 bypass via a trivial tuple wrapper
Confidence: **Very high** (branch inspection + 2 probes + control)

`suspend_prov_origins_from_rvalue` (`:493-509`) handles only
RK_REF/RK_ADDR_OF/RK_USE/RK_CAST; RK_AGGREGATE (and other kinds) yield empty
origins, which Assign (`:562-567`) copies onto the destination. The liveness
twin `suspend_gen_rvalue` (`:124-164`) propagates through aggregates via
`suspend_gen_agg_fields` (`:148-150`) — internal inconsistency, fix is to
mirror it.

## Notes (no finding)

- Yield-intrinsic set (`:261-278`) cross-checked against the full
  `MirIntrinsic` enum (`src/Mir.w:200-294`): every fiber-suspending
  intrinsic (FIBER_AWAIT/CLEANUP_AWAIT/SELECT/SELECT_BIASED,
  SCOPE_AWAIT_ALL, CHAN_SEND/RECV) is listed. `THREAD_SCOPE_JOIN_ALL` is
  absent, analyzed-and-clear: `rt/rt_core.w:4006-4025` blocks the OS thread
  in `with_thread_join` without yielding the fiber, so no suspension point
  exists and borrows stay valid (worker-wedging risk only, not soundness).
  Raw `TK_YIELD` terminators are rejected upstream per `src/Mir.w:48-49`.
  The set's "update me" comment is the right tripwire; nothing is missing now.
- Bit-vector helpers (`:49-81`) bounds-guard all writes (`suspend_set_bit`,
  `suspend_prov_set_local_origin`); reads default to 0 out of range. Frame
  sizing (`bb * local_count + local`, `((bb*lc)+local)*gc+gi`) is consistent
  between readers and writers. No OOB established.
- Dedup reporting (`suspend_reported_site`, `:690-695`) keys on
  span+local+origin — correct direction (no diagnostic storms observed).
- `suspend_bits_fill` 64-byte alloc for a one-Vec state (`:49-54`) is
  generous-but-sound; InternPool-cited precedent documented inline.
