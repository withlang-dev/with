# Primary verification — `src/MirLower.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `ed72c25a6444bdecad798b5c72060411d5cb1b4a9a80ebe0c8d73a1b06af4015`
Source examined: child 1-15275 complete + re-reads (7864-8000, 13560-14000,
8140-8200); primary: discriminant consumer :8150-8175 (full read), mut-fn/NK
census claims accepted as child evidence, plus all-probe re-runs below

## Scope examined

AST→MIR lowering: async/cancel, drop elaboration, patterns, calls, scopes.

Applicable overview targets examined: T4 (async lowering), T5 (drop
elaboration), T13 (lowering completeness), T23 (silent degradation), T24.

## Behavioral matrix

All 4 probes in `docs/audit/probes/mirlower/` re-run by primary:
`p1_disc_match`, `p2_struct_pattern`, `p3_async_await`, `p4_drops` — all
`check --validate-all` rc=0; `p3` runs `v=7 a=7 b=3` rc=0.

## Verdict: no finding — lowering complete on the probed surface

- The discriminant consumer (`:8164`, primary-read) takes raw
  `sema.disc_values` with no validation — confirming #1003's downstream
  half and its filed fix location (reject at SemaDecl, not here).
- Child's T4/T5 completeness claims (await/cleanup-await/select/scopes/task
  bindings; drop elaboration regions) corroborated by the passing
  validate-all + runtime probes; no unlowered-form degradation demonstrated.

## Notes

- Mut-fn/NK-coverage censuses recorded as child evidence (counts, not
  independently re-tallied by primary).
