# Primary verification — `src/SemaDiag.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: `48ebc9c694374f0672b72617c2d147d4d184ec57756bd8c2f5572e1a8e8e15c3`
Source examined: child 1-1435 complete (three reads); primary: spot re-runs
below + E0701/E0901/E1101/E1102/E1201/E0952/warning probes reviewed

## Scope examined

Diagnostic constructors and error-code coverage: each error code reachable,
correct span, correct severity.

Applicable overview targets examined: T10 (names in diagnostics), T18
(diagnostic quality), T23 (downgrades), T24 (overlap with
Diagnostic.w/DiagnosticRender.w).

## Behavioral matrix

Child's full error-code table (`docs/audit/probes/semadiag/`, all PASS per child
report); primary spot re-ran: `p_e0701` rc=1 (fires), `p_e0901_return` rc=1
(fires), `p_warn_partial_match` rc=0 (silent-ok as designed). Directions
match the child's coverage table; no contradiction found.

## Verdict: no finding — error codes fire with correct spans

Every probed code (E0901 return/break/continue/goto/`?`, E1101, E1102
including cascade, E1201, E0701 + plain-let negative, E0702, E0952, three
warnings) behaves as designed. The E0701 plain-let-held-guard silence is
correct (guard needs `guarded-with`/liveness, not mere binding) — and is
exactly what makes #999's aggregate evasion a hole rather than the norm.

## Notes (no finding)

- Child notes (E0952 span covers whole closure; E1102 cascade second error;
  E0701/E0702 closure paths share the emit fn at SemaCheck.w:4021/4024)
  recorded as child evidence; primary did not independently re-probe these
  minors — no filing either way.
