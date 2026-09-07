# Primary verification — `src/ComptimeEval.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `5a76e813c6d72c22bd882401de3c38e56fa9e3d4d1adf7888c0ad695730829e8`
Source examined: child 7992 complete + ComptimeValue/Transform/SemaCheck
windows; primary: all-probe re-runs below

## Scope examined

Comptime evaluation: I/O gating, step/recursion/memory budgets, failure loudness.

Applicable overview targets examined: T6 (effects), T8 (identity), T12 (limits), T23 (failures).

## Behavioral matrix

All 6 probes in `docs/audit/probes/comptime/` re-run by primary:
- `t06_io_rejected` rc=1 loud ("comptime can only call comptime functions") ✓
- `t23_divzero_loud` errors loudly with span ✓
- `t12_inf_loop` / `t12_inf_recurse` rc=1 (step limits bite) ✓
- `t08_int_identity` (child, accepted) + `t23_i64_silent` runs printing
  -1294967295 — STILL reproduces open #943 (commented with still-repro +
  isolation signal: limits work, only value narrowing is broken).

## Verdict: no new filing — limits loud, one known gap stays open

- Budgets (50000 steps, 256 recursion, string caps) all demonstrated working.
  I/O correctly gated by mode. Division by zero loud with span.
- The i64 truncation is #943 verbatim; primary posted a still-reproduces
  comment narrowing it (value narrowing only, limits fine).

## Notes

- Child's ComptimeValue/Transform region reads recorded as child evidence.
