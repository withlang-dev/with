# Primary verification — `src/Diag.w` + `src/Diagnostic.w` + `src/DiagnosticRender.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: Diag `0cacb4e2c2d16d58bc4a6f2842f06efe049589bc3cd0de76d0c0bad8078264a1`;
Diagnostic `7770907084739167606f20b8c141ce496e7b6547466b9e7bb0e5210fe9bd984a`;
DiagnosticRender `2cba2eef8095e28b7883d97769d10d7b216b447bdb36067956d14d1eaa05f7e3`
Source examined: child all three complete (+ Source.w/Span.w/emit paths);
primary: render core `Diagnostic.w:119-157` (full read), clamps + carets
`DiagnosticRender.w:15-69` (full read), multiline probe re-run below

## Scope examined

Diagnostic rendering: spans, severities, labels, notes, clamps, degradation.

Applicable overview targets examined: T18 (render quality), T23 (degradation).

## Behavioral matrix

- `e_multiline.w` (if-join type mismatch across lines 4-6): renders the
  error with span start `4:5` + 48-caret run on line 4 — first-line-only
  with correct location. Re-run by primary.
- Child's unit matrix (`r_units`, `r_degrade` incl. CJK cols, phantom lines,
  severity/gutter/label forms) recorded as child evidence; consistent with
  the clamp code primary read.

## Verdict: no finding — single-line rendering is a sane deliberate limit

- Multi-line spans render first-line-only with the location header at span
  start: always points at the right place, never crashes, carets clamped to
  120 (`span_underline_len`), columns clamped (200 + `...`). Degradation is
  bounded on every axis. A multi-line renderer would be nicer; its absence
  is not a defect.
- No unknown-code/empty-span crash demonstrated; child reports graceful
  degradation throughout.

## Notes

- Foundation `DiagnosticRender.w` overlap (second implementation) noted by
  child; not traced by primary — falls in a later foundation wave.
