# Audit: src/compiler/foundation/DiagnosticRender.w @ 450733e5 — COMPLETE

Verdict: COMPLETE

Scope: read-only audit of `src/compiler/foundation/DiagnosticRender.w` (92 lines)
at commit 450733e5. Full module read. Targets traced: T13 ownership/drop, T15
migration fidelity, T22 spec conformance. Callers traced via REGEX repo search;
legacy counterparts `src/DiagnosticRender.w` (69 lines) and `src/Diagnostic.w`
(render path, lines 99-157) fully read for fidelity comparison; `out/bootstrap/bin/with-stage1`
existence verified with `ls` and probed live (`check` on good/bad files).

## Findings

1. src/compiler/foundation/DiagnosticRender.w:8-48 (render_diagnostic) — OK
   (T22, probe: RAN live legacy render + line-for-line format comparison;
   refutation: live `with-stage1 check` output shape `error: msg` /
   ` --> path:line:col` / `1 | text` / `  | carets` matches the foundation
   format strings exactly, including `[code]` suffix, `label @line:col`,
   `note:`/`help:` prefixes, and blank-line separator between items in
   render_all_diagnostics :50-56 vs legacy DiagnosticList.render_all).
   No defect.
2. src/compiler/foundation/DiagnosticRender.w:58-92 (render_severity,
   span_underline_len, render_caret_line, clamp_i32) — OK (T15, probe: code
   read vs src/DiagnosticRender.w:35-69; refutation: logic is token-identical
   to the legacy helpers — same `"diag"` fallback, same 1..120 caret clamp,
   same 0..200 pad clamp with `" ..."` overflow marker; only the
   span_underline_len signature changed from `(start, end: i32)` to
   `(sp: Span)`, with identical arithmetic on `sp.len()`). No defect.
3. src/compiler/foundation/DiagnosticRender.w:32-37 (secondary labels omit
   file path) — info, NOT a defect (T15/T22, probe: code read vs
   src/Diagnostic.w:138-150; refutation vs in-repo callers: zero callers of
   the foundation render path exist — only `Mod.w:12` re-exports it — so no
   caller can observe this). Latent divergence noted: the foundation resolves
   each label against the correct file (`sm.offset_to_location(lab.span.file,
   ...)` gives the right line/col) but always prints `label @line:col`,
   while the legacy path prints `label {path}@line:col` when the label lives
   in another file (#670). Correct line/col, missing file identity; only
   matters if/when the foundation renderer gains callers. Not filed.
4. DiagnosticStore.emit (:69-70, via foundation/Diagnostic.w:70) lacks the
   #759 identical-diagnostic dedup present in legacy
   DiagnosticList.emit (src/Diagnostic.w:173-188) — info, NOT a defect (T15,
   probe: code read; refutation: same zero-caller argument as finding 3 —
   no in-repo caller pushes through the foundation store, so no double-render
   is observable; legacy dedup exists because comptime-transform sema and
   check_module both run declaration collection on the same AST). If the
   foundation store replaces the legacy list, port the dedup predicate with
   it. Not filed.
5. Foundation Diagnostic drops legacy `origin_file/origin_fn/origin_line/
   origin_node` + `set_origin` (src/Diagnostic.w:31-34,84-88) — info, NOT a
   defect (T15, probe: code read; refutation: neither renderer prints origin
   fields, and no foundation caller sets them; render output is unaffected).
   Not filed.
6. T13 ownership/drop — CLEAN (probe: full-module read). All inputs are
   borrows (`diag: &Diagnostic`, `sm: &SourceMap`); all outputs are fresh
   owned `str` built by `++`/f-string; `get_source` returns `&Source`
   (SourceMap.w:55-58 documents the no-copy rationale); `labels.get(i)` /
   `notes.get(i)` borrows are never stored; `Span` is `impl Copy` so
   by-value `span_underline_len(sp)` copies nothing ownable. No
   move/drop/clone/free surface in module. No defect.

## Probes run

- P1 (read): full module read, 92 lines, commit 450733e5 confirmed via
  `git rev-parse --short HEAD`; legacy `src/DiagnosticRender.w`,
  `src/Diagnostic.w` (:99-217), `SourceMap.w`, `Span.w`, `Ids.w`,
  `Source.w`, `Mod.w` fully read.
- P2 (callers, REGEX mode): `render_diagnostic|render_all_diagnostics|
  DiagnosticRender` over `src/` → only self + `Mod.w:12` re-export; legacy
  `render_all_diagnostics_frontend` callers (Zcu.w, Frontend.w, Compilation.w)
  all target the legacy `src/Diagnostic.w` path, never the foundation one.
- P3 (history): `git log --follow` shows foundation module evolving through
  copy-view-drop fixes (96f12487), by-value consume §3.8 (1f9ec562), f-string
  migration (9f8f5b94) — consistent with T13/T15 care, no adverse signal.
- P4 (binary, RAN): `ls -l out/bootstrap/bin/with-stage1` exists (114MB,
  Sep 3); `with-stage1 check` on bad file renders 3 errors in the exact
  header/location/source/marker shape the foundation module constructs;
  on good file prints `ok` (negative control: no diagnostics, no crash).
- P5 (sibling helpers, REGEX): `render_severity|span_underline_len|
  render_caret_line|clamp_i32` over `src/ test/ tests/` → hits only in
  `src/DiagnosticRender.w` + foundation module; no `seed/` dir exists.

## Negative controls

- N1: good file `check` → `ok`, proving the renderer emits nothing on the
  no-diagnostic path (both renderers share the empty-store loop shape).
- N2: no `seed/` directory in repo → T15 has no third migration source
  beyond the two compared renderers; nothing uncompared.
- N3: REGEX caller search proves zero live callers, so findings 3-5 cannot
  manifest behaviorally — recorded as observations, not defects, per the
  survive-refutation rule. No issues filed per instructions.

Verdict: COMPLETE
