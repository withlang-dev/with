# Primary verification — `lib/std/zlib/gzwrite.w`

Status: **INCOMPLETE** (runtime SIGSEGV finding F1, unlocalized; not filed)
Primary verifier: primary (partial source read + full API inventory + probe execution)
Source revision: `450733e5`
Source examined: 1139 lines; deep read lines 1–500 (`gzsetparams`, `gzwrite`,
`gzfwrite`, `gzprintf`, `gzputs`, `gzputc`, `gzflush`, `gzclose_w` entry
halves) + complete fn inventory via grep (8 pub, 5 priv: `gz_init`,
`gz_comp`, `gz_zero`, `gz_write`, `gz_vacate`). Remainder HELD.

## Scope examined

Write-side gz API: `gzsetparams` (`:16`), `gzwrite` (`:105`), `gzfwrite`
(`:147`), `gzprintf` (`:209`), `gzputs` (`:224`), `gzputc` (`:299`),
`gzflush` (`:379`), `gzclose_w` (`:440`), `gzvprintf` (`:496`). Callers:
`minigzip.w:gz_compress` (via `gzwrite`), `example.w:test_gzio` (via
`gzputc/gzputs/gzprintf`), user code via `gzopen("wb")`.

## Behavioral matrix (EXECUTED vs HELD)

- EXECUTED `with check lib/std/zlib/gzwrite.w` → rc=0 (log at
  `docs/audit/probes/zlib_gzwrite/check.log`). Checks clean.
- EXECUTED `docs/audit/probes/zlib_gzwrite/probe.w` → rc=**139 (SIGSEGV)**.
  Observed: `out_mixed.gz` created by `gzopen` but **0 bytes** (buffered data
  never flushed), `out_empty.gz` never created, `probe-gzwrite-done` never
  printed (`run.log` holds only compile warnings, no With diagnostic).
  Expected: `out_mixed.gz` gunzipping to
  `b"hello h world\nhello!\n"` + 2× the 31-B level-6 stream of `AB`*3000,
  and a valid empty gzip member in `out_empty.gz`. Crash site HELD: failure
  falls inside the file-1 sequence (`gzsetparams` → `gzputs` → `gzputc` →
  `gzputs` → `gzprintf` → `gzwrite` → `gzfwrite` → `gzflush` → `gzclose`)
  with no per-call observability; `compress_level` is exonerated (identical
  call succeeds in the deflate probe). Exact-line localization needs `lldb`
  on the stage1 binary — not done within batch budget.
- HELD: every write-path behavior (all 8 pub fns), `gzclose_w`-direct close,
  empty-file close — all blocked by F1. No oracle comparison was possible
  (no output bytes exist).

## Findings

- F1 (execution-verified, NOT filed): gz write path segfaults. Repro:
  `out/bootstrap/bin/with-stage1 run docs/audit/probes/zlib_gzwrite/probe.w`
  → rc=139, 0-byte `docs/audit/probes/zlib_gzwrite/out/out_mixed.gz`. Suspect set
  (hypotheses only, no line claimed): `gzprintf` C-vararg passing of a With
  `str` (same shape as `example.w:83`, also never executed here),
  `comp.ptr as *const c_void` marshalling, `gzsetparams` on a fresh stream.
  Refutation attempted: none possible without debugger; `check` passing shows
  it is not a type-level fault.

Verdict: INCOMPLETE
