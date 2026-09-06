# Primary verification — `lib/std/task.w`

Status: **Complete**
Primary verifier: root agent
Source revision: `450733e5`
Source SHA-256: `1ed056b6e2702b0683ce532d6b4986ce5bd6d6bfbabcd5702174e663f12239d7`
Source examined: all 233 lines

## Scope examined

The complete module was read inline. It defines `Task[T]` / `ScopedTask[T]`
(`:20-25`), the readiness scan `task_first_completed` (`:36-47`), five
combinators (`await_all` x2, `await_first`, `await_any`, `await_settled`),
and `with_concurrency` (`:230-233`). All blocking goes through the
cooperative `task_wait_for_progress` (`:29-34`); every combinator carries a
defer-based `join_cleanup` drain whose live-length bound comments were each
checked against the paired `remove` calls and found accurate.

Applicable overview targets examined: 4 (await/cancel discipline), 10
(stdlib foundations), 13 (Task construction contract from codegen), 23
(fallback silence). No allocation, no platform branch, no unsafe.

## Behavioral matrix

Probes in `docs/audit/probes/fiber_spawn_cap_1024/` (seed stage1, `-O1`):

- `bis.w` / `dbg3.w`: infallible `await_all` past 1024 tasks returns zeros
  (#995, filed from this audit leg).
- `hangres.w` (NEW): Result-`await_all` over 1100 all-Ok tasks hangs —
  60 s timeout, zero output, rc=124. Commented on #995.
- `conc.w` (NEW): `await_all(with_concurrency(build_tasks(1100), 1))`
  fails to compile — `return type mismatch` at `task.w:232` and `:233`
  with `no matching generic overload for 'await_all'` at the call site.
  Commented on #981.

## TASK-002 — readiness-scan combinators livelock past the spawn cap (in #995)

Classification: **Confirmed livelock; reported as a #995 comment**
Severity: **High** — infinite busy-loop, no output, must be killed
Confidence: **Very high** (execution + source chain)

`task_first_completed` requires `sequence > 0` (`:43`); a -1 pseudo-handle
never completes (`with_runtime_fiber_completion_sequence` misses lookup,
returns 0), so `ready < 0` forever. Once the 1024 real fibers drain,
`with_runtime_has_fibers() == 0` makes `task_wait_for_progress` a no-op and
`while pending.len() > 0` spins forever (`:77-83`, same shape in
`await_first` `:146-155` and `await_any` `:188-194`, the latter two by
inspection — same scan, same no-progress exit). Net: past the spawn cap,
infallible `await_all`/`await_settled` silently corrupt while Result
`await_all`/`await_first`/`await_any` livelock. One loud spawn diagnostic
fixes all five combinators.

## TASK-001 upgrade — `with_concurrency` is unusable, not merely ignored (#981)

`#981` filed the stub (`let _ = n; tasks`, `:230-233`) as a silent no-op.
Execution shows it is worse: instantiating it is a compile error inside the
embedded stdlib, misreported at the caller as overload-resolution failure.
The documented limiter — the only stdlib-level mitigation callers have for
#995 — cannot be called at all. Recorded as a comment on #981; no new issue
(the repair boundary there, `todo()` or the real limiter, is unchanged).

## Notes (no finding)

- Empty-input behavior is loud and consistent: `await_first` is `todo()`
  (`:128`), `await_any` returns `Err(empty)` (`:165-167`). The module's own
  convention is fail-loud, which is what makes the stub and the livelock
  stand out rather than blend in.
- `task_first_completed` is an O(n) scan per poll with per-entry extern
  calls — a scaling note for 10k+ task sets, not a defect.
- Defer-cleanup alignment verified in all five combinators: removals from
  `pending` stay in lockstep with `order`/`finished`, so the
  `cleanup_i < pending.len()` bound always names un-awaited tasks.
- `with values.slot(orig)` / `with errors.slot(orig)` in-place fill
  preserves input order without re-sorting — correct direction.
