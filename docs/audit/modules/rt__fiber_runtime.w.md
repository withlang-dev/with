# Primary verification — `rt/fiber_runtime.w`

Status: **Complete**
Primary verifier: root agent
Source revision: `450733e5`
Source SHA-256: `fa3c29f7ecdd1bdda56ea8d2078fc574c33b72fc564b13db03b486937c275731`
Source examined: all 320 lines

## Scope examined

The complete module was read inline. It is the platform-independent fiber
helper layer: await/cleanup-await, select-mode dispatch, cancel/detach
handoff, the 1024-slot detached-fiber table, unhandled-panic reporting,
runtime init/shutdown ordering, and the cancel-state accessors. All calls
into queue/context ownership go through `extern` core functions defined in
`rt/fiber_core_darwin.w` (and siblings); this module owns no locks, no
queues, and no context switching.

Applicable overview targets examined: 4 (suspension/cancellation), 13–14
(MIR/codegen contract — the Task `{fiber_id, result_buf}` construction this
module consumes), 15 (runtime foundations), 23 (fallbacks). No allocation
other than none (all buffers are caller-owned); deallocation appears only as
`with_free(result_buf)` on the detach paths.

## Behavioral matrix

Probes in `docs/audit/probes/fiber_spawn_cap_1024/` (bis.w, dbg3.w,
vec1024_probe.w), built with the seed stage1 at `-O1` on x86_64 Linux:

- `bis.w` (1100 tasks, `await_all`): `1100, 1024, 0, 0` — expected
  `1100, 1024, 1025, 1100`. Boundary exactly at 1024.
- `dbg3.w` (3000 tasks): indices 0..1023 correct, 1024..2999 read 0.
  Deterministic across runs, with `fiber_worker_count = 1` and `8`.
- `vec1024_probe.w` (plain `Vec[i32]`, 3000 push/get): all correct —
  negative control exonerating the container.

`with check --validate-all` was not re-run for these probes; the defect is a
runtime value-corruption path, not a validator rejection, and both
differential controls (worker count, container type) were executed.

## FIBER-CAP-001 — await of a failed spawn silently yields zero (filed #995)

Classification: **Confirmed correctness defect; reported upstream as #995**
Severity: **High** — silent wrong values, exit 0, deterministic past 1024
live fibers
Confidence: **Very high** (execution + full source chain)

Exact source chain:

1. `with_fiber_spawn` returns **-1** when `live_fiber_count >= MAX_FIBERS
   (1024)` (`rt/fiber_core_darwin.w:772-774`).
2. Codegen stores the raw return into `Task.fiber_id` with no check, in both
   spawn emitters (`src/CodegenDispatch.w:18362`, `18449-18464`).
3. `with_fiber_await(-1)` takes nothing from `fiber_take_completed`, then
   `with_runtime_fiber_is_live(-1)` returns 0 (`fiber_lookup` misses;
   `rt/fiber_core_darwin.w:1031-1038`), so await takes the immediate-return
   path (`rt/fiber_runtime.w:212-215`). Same shape in
   `with_fiber_cleanup_await` (`:246-249`).
4. Codegen loads the result from the never-written result buffer
   (fresh-alloc zeros observed) — silent 0.

This module already knows spawn can fail: `with_fiber_detach` and
`with_fiber_detach_cancel` both guard `fiber_id <= 0`
(`rt/fiber_runtime.w:266`, `286`), and detached-table overflow is fail-loud
(`fatal: too many detached fibers` + abort, `:277-279`, `:300-302`). The
await/cancel entry points do not honor the same contract — the defect is an
inconsistency inside this module's own convention, not just a caller bug.
`with_fiber_cancel` (`:260-263`) likewise forwards -1 to
`with_runtime_request_cancel` unchecked.

Five Whys: values are wrong because await returns without waiting; it
returns because is_live(-1) is 0; the id is -1 because spawn failed; spawn
failed because 1024 fibers were live; nobody diagnosed because no layer on
the spawn→Task→await path checks the -1 contract that the detach path in
this same file already encodes.

Related: #991 (CHAN-001) confirmed independent — its probe uses 2 fibers,
below the spawn cap. It stands as filed.

## Notes (no finding)

- `with_fiber_select_mode` (`:178-192`): empty/never-ready selection with no
  live fibers stores -1 — loud in the `Option` sense at the `select!`
  surface; not traced further in this pass.
- `with_fiber_was_cancelled_return` (`:314-317`): single-flight
  `last_await_*` globals are keyed by fiber id with a
  `with_runtime_completed_cancelled_return` fallback — no cross-task
  staleness established; read as sound pending a cancellation stress probe.
- `with_runtime_shutdown` (`:85-94`): drains detached fibers and tears down
  the core before the debug-alloc leak walk — ordering is explicitly
  documented and correct-direction.
- `fiber_report_unhandled_panics` (`:58-80`): fail-loud (exit 1) with the
  fiber id and message — the module's loud convention, contrasting with the
  silent await path above.
