# Primary verification — `src/CodegenTraits.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `bd3bec50ad54f4292278fad0e1b8dcf72c1ce59f6cd6a7ed7dc2814894b57f6d`
Source examined: child 1-2529 complete (five reads); primary: vtable builders
990-1035 + 1075-1128 + 1136-1189 (full read), table-shape audit region
cited 107-193 by child, plus full probe-matrix re-runs below

## Scope examined

Trait vtable construction (plain, monomorphized, generic-inst), dyn wrappers,
dispatch emission.

Applicable overview targets examined: T2-3 (dispatch correctness), T13-14
(codegen validity), T23 (No Silent Fallbacks), T24 (builder overlap).

## Behavioral matrix

All probes in `docs/audit/probes/codegentraits/` re-run by primary:

- `ct_missing_dyn.w` (dyn-call the omitted method): `check` ok rc=0,
  `--validate-all` ok rc=0, built binary traps rc=133, no output. Filed #1002.
- `ct_missing_call.w` (static call of omitted method): rc=1 loud
  ("unknown method") — negative control passes; only the dyn path traps.
- `ct_missing_method.w` (omit + never call): rc=0 — by #988's fail-late
  design (accepted at impl site); coherent with the above, not a
  contradiction.
- `ct_duplicate_impl.w` rc=1; `ct_dyn_self_return.w` rc=1 (not object-safe);
  `ct_positive.w` check rc=0 + run `ct-ok` rc=0 — dispatch works when the
  impl is complete.

## VTABLE-001 — null slot on omitted method (filed #1002)

Classification: **Confirmed silent wrong-codegen → runtime trap; #1002**
Severity: **High** — deterministic rc=133, zero diagnostic
Confidence: **Very high** (branch + check/validate/build/run + 5 controls)

Plain vtable builder pushes `wl_const_null` for unresolvable slots
(`:1034-1035`); both siblings diagnose loudly (`:1110-1113`, `:1178-1181`,
eprint + `had_error=1`). Either layer going loud fixes the trap; #988 covers
the declaration-site half.

## Notes (no finding)

- Positive dispatch (static + default + dyn) verified working end to end.
