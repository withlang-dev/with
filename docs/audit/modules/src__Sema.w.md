# Primary verification — `src/Sema.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `5c4363799bb01610336a61e7be7159f5a036c72b8416c23fe1fa235babab9078`
Source examined: child 1-7313 complete (seven chunks); primary:
`expr_view_depends_on_origin` :5240-5304 (full read), dep-sidecar writers
:5133/:5558-5560, plus all-probe re-runs below

## Scope examined

Type identity/canonicalization, symbol tables, view-origin substrate
(`sig_param_view_origin`, `expr_view_dep_*`, `binding_view_dep_*`).

Applicable overview targets examined: T6 (provenance substrate), T8 (type
identity), T10 (names), T23, T24.

## Behavioral matrix

All 6 probes in `docs/audit/probes/sema_main/` re-run by primary:
`p_alias_identity` rc=0 / `p_shadow_reject` rc=1 / `p_view_call_mutate` rc=1 /
`p_view_local_escape` rc=1 / `p_view_param_passthrough` rc=0 /
`p_view_tuple_smuggle` rc=1. The view system — including tuples and calls —
behaves correctly end to end.

## Verdict: no filed finding; T24 structural note retained

- The three provenance walkers (`Sema.expr_view_depends_on_origin`,
  `SemaCheck.collect_expr_view_deps`, `SemaCheck.compute_expr_view_origin_mask`)
  each handle a DIFFERENT explicit arm subset and lean on sidecar tables for
  the rest. Primary verified the much-cited "missing NK_TUPLE" claim is
  overstated: `collect_expr_view_deps` handles TUPLE/ENUM_VARIANT/STRUCT/
  ARRAY/MAP explicitly (`:9725-9768`); only CALL delegates to the sidecar,
  and `compute_expr_view_origin_mask` handles TUPLE/ENUM_VARIANT with the
  rest via the param-origins sidecar (`:9836-9838`).
- No observed misbehavior in any walker (probe matrix all-correct). The
  retained note is maintainability, and it matters to the audit's decision
  gate: three hand-synced parallel implementations of one provenance rule is
  the duplicated-seam disease — the next arm added to one walker but not
  the other two is a #999-class hole waiting to happen. Not filed (no
  behavior), flagged for the decision record.
