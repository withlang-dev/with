# Primary verification — `src/SemaCheck.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `1ab4369ea79752d896d2e063b9ed76f67e54e0b984e71bf8f940afc6d58331d5`
Source examined: child broad coverage (783-fn outline + ~25 regions incl.
16766-17095, 8944-9023, 19971-20100, 21898-22117, 23165-23364, 23959-24058);
primary: `subst_vec_lookup` :16952-16965 + all 9 call sites, `resolve_type_node_with_subst` :7572-7613,
`collect_expr_view_deps` :9656-9773, `compute_expr_view_origin_mask` :9775-9838 (full reads),
plus all-probe re-runs below

## Scope examined

Call/method resolution, borrow/view enforcement, generics, closures,
pattern checking, substitution.

Applicable overview targets examined: T2-3, T5, T6, T8-9/12, T10, T23, T24.

## Behavioral matrix

All 8 probes in `docs/audit/probes/semacheck/` re-run by primary, directions match child report:
`sc_borrow_expiry_ok` rc=0 / `sc_borrow_live_neg` rc=1 / `sc_field_move_implicit_neg` rc=1 /
`sc_field_move_explicit_ok` rc=0 / `sc_trait_ret_mismatch_neg` rc=1 /
`sc_trait_ret_unannotated_ok` rc=0 (deliberate per #988) / `sc_mono_two_inst_ok` rc=0 /
`sc_closure_capture_neg` rc=1.

## Verdict: no filed finding

- F1 (name-string fallback in `subst_vec_lookup`, `:16956-16965`): contained.
  Exact-sym match tried first; string fallback returns a type only on exactly
  one match (`found_count == 1`), else 0 — and every caller treats 0 as
  "resolve without substitution" (`:7580-7583`, `:7623-7626`), i.e. the
  failure direction is incompleteness, never a wrong type. A wrong
  substitution needs two same-named distinct symbols with exactly one in the
  list — contrived, undemonstrated. Hygiene note (symbol-identity system
  doing string comparison), not a defect.
- View-dep collectors (`collect_expr_view_deps`, `compute_expr_view_origin_mask`):
  structurally overlapping with `Sema.expr_view_depends_on_origin` (each covers a
  different explicit-arm subset; sidecar tables cover the rest) — T24 note, see
  Sema.w evidence file. End-to-end behavior correct per probe matrix.

## Notes

- Child's remaining minors (E0952 span, E1102 cascade, closure emit-fn sharing)
  recorded as child evidence; no independent filing either way.
