# Audit: src/compiler/foundation/Span.w @ 450733e5

- Commit: 450733e5 (HEAD verified via `git rev-parse --short HEAD`)
- Module: 40 lines, `pub type Span { file: FileId, start: i32, end: i32 }`, `impl Copy`,
  `span_zero`, `Span.len/is_valid/merge`, private `span_min_i32/span_max_i32`.
- Targets traced: T13 ownership/drop, T15 migration fidelity, T22 spec conformance.

## Probes run
- P1 (positive): `./out/bootstrap/bin/with-stage1 check src/compiler/foundation/Span.w` → `ok`
  (binary verified present via `ls -la out/bootstrap/bin/with-stage1`; note the
  task-suggested `seed`/`bootstrap/bin/with-stage1` paths do NOT exist — no `seed/`
  dir, no `bootstrap/bin/`; the real binary is `out/bootstrap/bin/with-stage1`).
- P2 (negative control): `check src/compiler/foundation/NoSuch.w` →
  `error: cannot open ... / error: check failed during compilation`, confirming the
  P1 `ok` is a real pass, not a vacuous harness success.

## Caller analysis (REGEX-mode searches, `src/compiler` scope)
- `Span.len` has one live in-repo caller: `DiagnosticRender.w:68` (`let n = sp.len()`).
- `span_zero`, `Span.is_valid`, `Span.merge` have ZERO callers under `src/compiler/`
  (only their definitions at Span.w:12,22,25 match). `Diagnostic.w` stores `Span`
  by value in `Diagnostic`/`DiagnosticLabel` and takes `Span` by value in
  `diagnostic_error/warning` + `add_label(span: Span)` — consistent with a Copy type.
- `Compilation.w` / `Frontend.w` use bare `use Span`, which resolves to the legacy
  root `src/Span.w`, not `compiler.foundation.Span`; they construct
  `Span { file: ... }` literals directly. The legacy `src/Span.w` (span_zero,
  is_valid, span_min_i32, merge) is a parallel implementation with the same shape —
  maintainer-chosen scaffolding during wave-1 migration, not a deviation.

## Findings
No defects. Each candidate below was refuted vs in-repo callers and landed-commit intent:

1. Span.w:25, low/T22, NOT-A-DEFECT (probe: P1 pass) — `merge` unions start/end
   without a same-file guard. Refutation: the parallel legacy `src/Span.w:34`
   implements identical min/max union semantics; no in-repo caller passes
   cross-file spans to either; changing one side alone would create the very
   divergence T15 guards against.
2. Span.w:12-17, low/T22, NOT-A-DEFECT — `span_zero` uses `file 0` rather than
   `file_id_invalid (-1)`. Refutation: `file_id_is_valid` (Ids.w:42) is `id >= 0`,
   so file 0 is valid by spec, and foundation callers' siblings (`Compilation.w:161`,
   `Frontend.w:1421,1436,1812`) all use `file: 0` as the placeholder convention.
3. Span.w:25 `[merge(self: &Self, other: Span)]`, T13, NOT-A-DEFECT — by-value
   `other` under §3.8 consume rules. Refutation: `Span` is `impl Copy`
   (added deliberately in 1f9ec562 "Enforce §3.8 by-value consume"), so by-value
   passing copies; read receivers (`&Self` on len/is_valid/merge) match the
   a27c9e3e eliminate-self-receiver migration exactly. `git show` of both commits
   confirms each hunk on this module is the intended mechanical change.
4. Dead code (`span_zero/is_valid/merge` uncalled in `src/compiler/`), T15,
   NOT-A-DEFECT — refuted as wave-1 scaffolding: the foundation tree is new
   parallel construction alongside the live legacy root modules; only `len` is
   consumed so far (`DiagnosticRender.w:68`). No migration-plan deviation
   (no plan mandates immediate callers).

## Verdict
Verdict: COMPLETE — no actionable defects; module typechecks under stage1 (P1 ok, P2 negative control behaves).
