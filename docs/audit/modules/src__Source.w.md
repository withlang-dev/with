# Audit: src/Source.w @ 450733e5

- Commit: 450733e5 (`build: the regex runtime shim compiles pcre2 from source under any compiler`)
- Module: `src/Source.w` (88 lines)
- Targets traced: T13 ownership/drop, T15 migration fidelity, T22 spec conformance
- Seed compiler: `out/bootstrap/bin/with-stage1` (exists; `bootstrap/bin/with-stage1` absent — used `out/...`)

## Source summary (full 88-line read)

Wave 1 foundation: source text + line mapping. `Source { path: str, text: str, line_offsets: Vec[i32], file_id: i32 }`,
`SourceLocation { line, col }` (0-based, byte col), alias `Location = SourceLocation`.
`Source.from_string` clones path/text via `with_str_clone_ref`, computes offsets; `Source.from_file` reads via
`with_fs_read_file` then delegates. Methods: `line_count` (offsets len), `offset_to_location` (clamp + binary
search over offsets), `line_text` (slice + strip single trailing byte 10), free fn `source_compute_line_offsets`
(seed 0, push i+1 after each byte-10), `deinit` no-op ("No-op in current runtime model").

## T13 ownership/drop

- Grep `drop|own|free|close|release|borrow|move` in module: no matches (EXECUTED).
- `from_string` clones both strings (correct acquisition); `deinit` is an explicit no-op.
- Refutation: sibling convention grep `fn deinit` across `src/*.w` shows foundation value types currently use
  no-op deinit under the same runtime model (no per-type free yet); no caller frees `Source` fields individually
  and no double-free path exists in the module itself. Not a defect on this module alone — no finding filed.
  If the repo later adopts per-type drop, this `deinit` is the known hook point (line 84-87).

## T15 migration fidelity

- Grep `migrat|legacy|compat|shim|deprecated|old_` in module: no matches (EXECUTED). No migration markers in file.
- In-repo callers referencing `Source` include `src/Migrate.w`, `src/Codegen*.w`, `src/Sema*.w`,
  `src/AnalysisTypes.w`, `src/BuildGraphCache.w` (library list probe EXECUTED). `Migrate.w` consumes `Source`
  as input context; nothing in this module performs C-to-With translation, so fidelity N/A. No finding.

## T22 spec conformance (hand trace + probes)

- `source_compute_line_offsets`: `""` -> `[0]` (line_count 1); `"a\nb"` -> `[0,2]`; trailing `"\n"` pushes
  `len` (standard one-past-end sentinel). Consistent with `line_count = offsets.len()`.
- `offset_to_location`: `offset<=0` -> `(0,0)`; clamp to `text.len()`; binary search first offset `> clamped`,
  `line = lo-1`; `col = clamped - line_start` (byte col, matches doc comment). Empty text safe
  (`line_offsets=[0]`, `line=0`, `col=0`).
- `line_text`: out-of-range -> `""`; last line `end=text.len()`; strips exactly one trailing byte-10.
  Observation (not filed): lone-`\n` strip leaves a `\r` on CRLF inputs, and only one `\n` is stripped per line
  (by construction each line holds at most one). Refutation: offsets split only on byte 10 and columns are
  documented byte columns, so `\r` retention is consistent with the byte-oriented model; no in-repo caller or
  test asserts CRLF stripping. No defect filed.
- Grep `spec|todo|fixme|unimpl|assert|panic|unreachable` in module: no matches (EXECUTED).

## Probes

- `out/bootstrap/bin/with-stage1 check src/Source.w` -> `ok`, exit 0. Status EXECUTED.
- Negative control `check /tmp/bad_probe.w` (truncated fn) -> parse/type error (non-ok), confirming the
  `ok` above is discriminating, not vacuous. Status EXECUTED.
- Behavioral `run` probe of `offset_to_location`/`line_text` edge cases: HELD — module is a library with no
  `main`; `run` requires an entry point and linking a harness would test a copy, not the module. Hand-trace
  above + `check ok` is the evidence.
- Grep probes (T13/T15/T22 patterns) + caller list probe: EXECUTED (outputs in this report).

## Findings

None. No defect survived refutation; no file:line to cite.

## Verdict: COMPLETE
