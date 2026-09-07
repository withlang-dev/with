# Primary verification — `rt/panic_runtime.w` + `rt/fiber_stubs.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: panic_runtime `36326d889cb3955045f085c7cba26764bdb9c26035e484b17ca439b342f71173`;
fiber_stubs `1405cc5b1ab6c5621802e9aad543c367dba4fa9d8ef4ff02e02e3b43d03a9d70`
Source examined: primary FULL READ of both (panic_runtime 1-33, fiber_stubs 1-110),
plus all-probe re-runs below

## Scope examined

Panic surface (rendering, fiber capture, exit codes) and the no-fiber fallback stubs.

Applicable overview targets examined: T4 (panic paths), T15 (stub discipline), T23 (loudness).

## Behavioral matrix

All probes in `docs/audit/probes/rt_small/` re-run by primary (`run` rc=134 all):
`panic_msg` (stderr `panic at ...:2:5: boom-rt-small`), `panic_assert_eq`
(`assertion failed 1!=2`), `panic_todo` (unfinished marker), `await_fiber_panic`
(fiber capture, await reprints `fiber-boom-rt-small`).

## Verdict: no finding — every path loud with locations

- Thread panic: ewrite + `_exit(134)` (`panic_runtime.w:31-33`; 134-not-abort
  is Windows-compat, documented at fiber_runtime.w:125-127).
- Fiber panic: capture (no ewrite at capture — correct, the fiber may be
  awaited elsewhere), reprint at await with original location, exit 134.
- `rt_libc_exit(134)` after `with_fiber_panic_capture` is dead code (capture
  switches away and never returns) — harmless belt-and-suspenders.
- Stubs form a consistent zero-fiber trio: `is_live=0` + `take=0` + `await`
  no-op agree with each other; `worker_count=1`/`current_worker=0` sane
  degenerates; `panic_capture` aborts loud. `with_fiber_spawn` is absent, so
  no Task can exist to reach the `detach`-without-free path — the one
  asymmetry (stubs `detach` returns 0 without freeing `result_buf`, unlike
  fiber_runtime.w which frees on invalid id) is unreachable. Noted, not filed.

## Notes

- Child's cross-contrasts (darwin/windows take paths, rt_core call sites)
  recorded as child evidence.
