# Primary verification — `src/Resolve.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `a57bd66aaa820f7572afcc2b1a817b5af7efa41b007afb22400e0426b8d49436`
Source examined: child 1-1411 complete; primary: `add_binding` :476-484
(full read), `lookup_binding` cited :1011-1024 (accepted as child evidence),
Pass1 ordering cited :345-421 (accepted), plus full probe-matrix re-runs below

## Scope examined

Name resolution: binding insertion, scope lookup, forward refs, imports.

Applicable overview targets examined: T8 (identity), T10 (resolution/
shadowing), T23 (unresolved-name behavior), T24 (#660 id class).

## Behavioral matrix

All 5 probes in `docs/audit/probes/resolve/` re-run by primary: `t10_shadow`,
`t10_inner_shadow`, `t10_param_shadow` all rc=1 with `error: shadowing is
not allowed for 'x'` + exact span (verified message text); `t10_forward_ref`
rc=0; `t10_import_use` rc=0.

## Verdict: no finding — silent layer contained by a loud layer

- `add_binding` (`:476-484`, primary-read) overwrites same `(scope,sym)`
  silently (map insert, last-wins) — the child's T10 flag is real code, but
  UNREACHABLE for shadowing programs: Sema bans shadowing one layer up with
  a precise diagnostic (all three shadow shapes rc=1, message verified).
  Defense in depth holds; the silent map is never the decider.
- Forward refs (Pass1 reserves defs before bodies) and import-use resolve
  correctly per probes. Import-layer last-wins (#993) is a distinct open
  issue at another layer, not this one.

## Notes

- `lookup_binding` innermost-outward order and Pass1 structure recorded as
  child evidence (ranges cited, behavior corroborated by probes).
