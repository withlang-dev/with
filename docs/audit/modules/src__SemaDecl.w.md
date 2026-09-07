# Primary verification — `src/SemaDecl.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `3e48fcebbb87550837324805b0696aaf119c058b50d71d23ca082914e04ec60c`
Source examined: child 1-3054 complete; primary: enum-decl region 767-815
(full read), extern-default 1650-1660, repr-type threading 291-296/453-454/
2649/2804, plus all-probe re-runs below

## Scope examined

Declaration typing: type/function/extern/impl/generic decl collection,
discriminant validation, Copy/Drop derivation, name resolution support.

Applicable overview targets examined: T2-3 (decl typing/ABI surface), T8-9/12
(identity/generics), T10 (names), T23 (silent fallbacks), T24 (shared vs
re-derived rules).

## Behavioral matrix

All probes in `docs/audit/probes/semadecl/` re-run by primary (`check`,
rc quoted):

- `copy_drop` rc=1 / `copy_ok_neg` rc=0; `dup_disc` rc=1 / `dup_fn` rc=1 /
  `dup_fn_neg` rc=0; `type_cycle` rc=1 / `type_cycle_neg` rc=0;
  `unknown_trait` rc=1; `extern_shadow` rc=1; `generic_infer` rc=1 with a
  precise message ("cannot infer type parameter 'T'…annotate the result
  binding…") / `generic_infer_neg` rc=0; `share_place` rc=0;
  `extern_noret` rc=0 (Unit default, documented intentional at :1652-1655).
- `disc_range` (i8/200) rc=1; `dup_disc` rc=1 — the checks that exist work.
- `disc_u8_range` (u8/300) rc=0; `disc_u32_neg` (u32/-1) rc=0 — THE GAP.
- Runtime probes (primary-authored): `disc_rt.w` prints 44 then SIGSEGV
  rc=139, deterministic 3/3; `disc_rt2.w` exits 0 printing nothing
  (silent no-match).

## DISC-001 — repr-gated discriminant validation (filed #1003)

Classification: **Confirmed crash-class Sema gap; reported as #1003**
Severity: **High** — check-clean deterministic segfault
Confidence: **Very high** (branch + 4 check probes + 2 runtime probes)

`SemaDecl.w:788-794` validates range only for `ty_i8`/`ty_i16`; all other
reprs skip validation while duplicate detection (`:785-787`) still runs.
Raw values enter the type record (`:795`) and narrow silently downstream:
u8/300 → 44 + match trap; u32/-1 → wrap + silent no-match with no
exhaustiveness complaint.

## Notes (no finding)

- Child's T23 sweep (37x `.unwrap` all guarded; `put_generic_subst`
  fallback cascade-only; `try_resolve_disc_enum_value` -1 checked by
  callers) spot-held on the regions primary read; no silent-default path
  found in the examined regions.
- T24: Copy/Drop derivation uses shared helpers per child; primary did not
  independently re-derive this — recorded as child evidence, not primary.
