# Audit — `src/compiler/foundation/Diagnostic.w`

Status: **Complete**
Source revision: `450733e5`
Source examined: all 81 lines (full read, single file)

## Scope examined

Wave 1 foundation diagnostics model: `DiagSeverity` (`:6-9`),
`DiagnosticLabel` (`:11-14`), `Diagnostic` (`:16-24`),
`DiagnosticStore` (`:26-28`), `diagnostic_owned_text` (`:30-31`),
`diagnostic_error`/`diagnostic_warning` (`:33-53`), `impl Diagnostic`
setters (`:55-62`), `DiagnosticStore.init`/`emit`/`count`/`count_by_severity`/`has_errors`
(`:64-81`).

Applicable audit targets examined: T13 (ownership/drop), T15 (migration
fidelity vs `src/Diagnostic.w`), T22 (spec conformance). Sibling read:
`src/compiler/foundation/DiagnosticRender.w` (all 92 lines),
`src/compiler/foundation/Mod.w`, `src/Diagnostic.w` (all 217 lines),
`src/DiagnosticRender.w` (`:1-60`); callers via REGEX search
(`DiagnosticList|Diagnostic\.err|foundation\.Diagnostic`,
`set_origin|origin_file|Diagnostic\.warn|SEV_ERROR|SEV_WARNING`,
`compiler\.foundation`); spec `docs/with-specification.md` diagnostic
matches; plan `docs/completed/with-selfhost-wave1-replace-root-modules.md`.

## Probes run

Seed stage1 verified present (`out/bootstrap/bin/with-stage1` lists
`build/run/check/test/...`). All probes run from repo root at 450733e5:

- `check src/compiler/foundation/Diagnostic.w` → `ok`, rc=0.
- `run test/internals/diagnostic_test.w` → `ok`, rc=0 (exercises
  constructors, setters, store emit/count/filter, full render string
  equality).
- `run test/internals/diagnostic_multilabel_determinism_test.w` → `ok`,
  rc=0.
- `run --debug-alloc test/internals/diagnostic_test.w` → `ok` + 2x16-byte
  LEAK, leak count=2, rc=0.
- Negative controls under `--debug-alloc`: `span_source_test.w` → `ok`,
  leak count=0; `ids_test.w` → `ok`, no leaks; `source_map_test.w`
  (no Diagnostic import) → `ok` + identical 2x16-byte LEAK, leak count=2;
  `diagnostic_multilabel_determinism_test.w` → same 2x16-byte LEAK.

## Findings

No numbered defect findings. Every candidate below was refuted against
in-repo callers or controls:

1. (T15, refuted as live defect) Foundation `Diagnostic` lacks the root
   model's `origin_file/origin_fn/origin_line/origin_node` fields
   (`src/Diagnostic.w:31-34`), `set_origin` (`:84-88`), `Diagnostic.err`
   /`Diagnostic.warn` constructors (`:74-78`), `SEV_ERROR/SEV_WARNING`
   and `Label` aliases (`:16-17,:25`), and the store is named
   `DiagnosticStore` with plain push-`emit` (`Diagnostic.w:70`) instead of
   `DiagnosticList` with #759 dedup-`emit` (`src/Diagnostic.w:173-188`),
   `deinit`, `render/render_all/render_warnings`. Refutation: zero
   non-test in-repo callers import `compiler.foundation.Diagnostic` —
   the only importers are `DiagnosticRender.w:6`, `Mod.w:11`, and
   `test/internals/diagnostic*.w`. All live compiler paths
   (`SemaDiag.w`, `Sema.w`, `SemaCheck.w`, `Parser.w`, `Frontend.w`,
   `Compilation.w`, `Zcu.w`, `Analysis.w:692` reading `diag.origin_file`,
   etc.) use root `Diagnostic`/`DiagnosticList`, which is untouched at
   this commit. The wave1 replace-root plan (Commit 4, replace
   `src/Diagnostic.w` with the foundation implementation) is still
   pending — `src/Diagnostic.w` retains the old model — so these are
   migration-debt notes for that commit, not live breakage. In
   particular the missing dedup means a future swap without porting the
   #759 guard would re-introduce double-rendered decl-phase errors; and
   `Diagnostic.warn`/`set_origin`/`origin_file` have live callers that
   the replacement must satisfy.
2. (T13, refuted) `diagnostic_owned_text` uses `text.clone()`
   (`:30-31`) where the root model and sibling foundation modules
   (`Types.w:6`, `Values.w:4`) use `extern fn with_str_clone_ref`.
   Refutation: both `diagnostic*.w` runtime probes print exact expected
   output rc=0, so `.clone()` is functionally correct here; the
   divergence is stylistic/fidelity, not an ownership defect. No
   double-free signal: `--debug-alloc` shows no DOUBLE FREE, only the
   leak below.
3. (T13, refuted as Diagnostic-specific) The 2x16-byte `--debug-alloc`
   leak reproduces identically in `source_map_test.w`, which never
   imports foundation `Diagnostic`, and is absent in `span_source_test.w`
   / `ids_test.w`. The leak therefore tracks `SourceMap` (or the shared
   `add_source_text` path), not this module. No `emit`-by-value aliasing
   failure demonstrated: `store.emit(d)` followed by further use of the
   store runs clean rc=0, and `count_by_severity`'s `.get()`-copy read
   pattern matches the root module's own accepted pattern
   (`src/Diagnostic.w:196`).
4. (T22, no finding) No spec clause governs this module's API shape; the
   §22.3 diagnostic contract constrains borrow-checker rejection content,
   not the `Diagnostic` struct. Rendered output is byte-exact per the
   foundation render tests. Nothing to file.

## Negative controls

- REGEX (not literal) searches used throughout; the `|` patterns above
  return empty under literal mode and full results under `mode: regex`.
- `span_source_test.w` + `--debug-alloc` → leak count=0 proves the
  allocator instrument is capable of a clean verdict on foundation code,
  so the 2x16 leak in diagnostic tests is signal, localized to
  SourceMap by the `source_map_test.w` control — not harness noise, and
  not this module.
- Live-caller search confirms the foundation module is currently
  test-only surface; no production path can observe its API gaps.

## Verdict: COMPLETE — sound direction, no filed finding
