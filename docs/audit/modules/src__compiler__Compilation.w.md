# Primary verification — `src/compiler/Compilation.w` (+ `src/Compilation.w` shim)

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `fca845fe5a74616d34617fad2abf1eecd649a44c9037ee3a1faf97fb09ed7877`
(`src/Compilation.w`: `84a724d54d44ad5a7d0348123c5159603dec0ec27da052f2422f84a60d2cefcc`
— 8-line re-export shim, read in full by primary)
Source examined: child 1950/1950 (four reads) + shim + Config.w + main.w
lane windows; primary: `use compiler.Compilation` probe (rc=0), ok/type-err/
parse-err check probes, `run` probe — re-runs below

## Scope examined

Pipeline orchestration: phase ordering, freeze discipline, error gating,
link plan, execution.

Applicable overview targets examined: T18 (ordering/freeze), T21 (lanes),
T23 (failure propagation), T24 (shim overlap).

## Behavioral matrix

Probes in `docs/audit/probes/compilation/` + `docs/audit/probes/check_shim/`,
re-run by primary: `probe_ok` check rc=0; `probe_type_err` loud rc=1
("type mismatch in binding" + span); `probe_ok` run `probe-ok` rc=0;
`probe_use_compiler_compilation` (`use compiler.Compilation`) rc=0.

## Verdict: no finding — ordered, gated, frozen correctly

- Child's pipeline trace (compile→hooks→MIR→cache→link→execute, each gated
  on clean diagnostics) corroborated by the probe directions: type/parse
  errors stop the lane loudly; child also reports no binary/.o leftovers on
  failed build (cleanup direction correct).
- Freeze discipline (freeze post-lower/pre-codegen; no frozen re-entry)
  recorded as child evidence; consistent with the absence of any
  frozen-mutation diagnostic in the battery.
- `src/Compilation.w` is a pure re-export shim (8 lines, primary-read);
  `use compiler.Compilation` resolves rc=0. No behavior hides there.

## Notes

- Child's main.w lane windows + Config.w read recorded as child evidence.
