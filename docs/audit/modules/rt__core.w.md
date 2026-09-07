# Primary verification — `rt/rt_core.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `48c08e00c1a192ab71c6cf344de67a04513e693c8b035007c999ef585d7b9369`
Source examined: child 1-4032 complete; primary: fiber extern block
:3776-3800 (full read, signatures match fiber_runtime/fiber_core/stubs),
`check rt/rt_core.w` rc=0

## Scope examined

Runtime core: fiber extern surface, scope helpers, alloc/string/int foundations.

Applicable overview targets examined: T4 (extern surface), T15
(foundations), T22/T23 (recorded as child evidence).

## Verdict: no finding — externs match, one benign asymmetry

- 7/8 fiber externs match their definitions exactly (names, arity, types);
  the 8th (`take_completed_fiber`) matches too — the child's "non-unsafe
  extern vs unsafe def" note is the file's own documented pattern (comment
  :3785-3787; sole call via the unsafe wrapper :3788-3789). Deliberate, loud
  about it. Not a defect.
- `check` clean rc=0.

## Notes

- Child's alloc-freelist/mmap + string/int-helper reads recorded as child
  evidence; no behavioral divergence attached to any of them.
