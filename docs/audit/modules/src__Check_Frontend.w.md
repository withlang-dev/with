# Primary verification — `src/Check.w` + `src/Compilation.w` (shims) + `src/compiler/Frontend.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: Check.w `0c856468b828b38e88430670b0ce424800543797e6b98afef6d5482d3b11ec68`;
Compilation.w `84a724d54d44ad5a7d0348123c5159603dec0ec27da052f2422f84a60d2cefcc`;
Frontend.w `65f21e4455c0d5c9e9fdf6cefd0a2da0205dfd9dc1061d9c58eb5af6a501860f`
Source examined: child all three complete (Frontend 1-2513 + main.w dispatch
window); primary: both shims FULL READ (8 lines each), Frontend check entry
:1730-1753 (full read), plus probe re-runs below

## Scope examined

Frontend entry: shim surfaces, check pipeline wiring, CLI dispatch.

Applicable overview targets examined: T18 (entry/pipeline), T21 (lanes), T23 (flag behavior).

## Behavioral matrix

Probes in `docs/audit/probes/check_shim/` re-run by primary:
`probe_use_compiler_compilation` (`use compiler.Compilation`) rc=0;
`use Check` resolves (the `probe_check_shim` rc=1 is seed-vs-HEAD drift
INSIDE Sema.w — `primitive_type_by_sym` unknown to the older seed at
Sema.w:1195 — unrelated to the shim, expected bootstrap evolution).

## Verdict: two cosmetic notes, no filing

- `Check.w` comment ("Coordinates Sema initialization and module checking
  into a single call") overclaims an 8-line file with zero fns that only
  carries `use` decls; the real entry is `Frontend` check wiring (:1730+,
  primary-read: config threading into `check_module()` is explicit and
  complete). Comment drift, not behavior.
- `Compilation.w` re-exports the path, not the type name (callers qualify
  `Compilation.`); works (rc=0), slightly awkward. Note only.

## Notes

- Child's main.w dispatch window + flag matrix recorded as child evidence.
