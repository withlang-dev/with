# Primary verification — `lib/std/zlib/example.w`

Status: **INCOMPLETE** (checked clean; self-test suite never executed; not filed)
Primary verifier: primary (partial source read + full API inventory + check execution)
Source revision: `450733e5`
Source examined: 914 lines; deep read lines 1–500 (`test_compress`,
`test_gzio` incl. gzputc/gzputs/gzprintf/gzseek/gzread/gzgetc/gzungetc/gzgets,
`test_deflate`, `test_inflate`, `test_large_deflate`, start of
`test_large_inflate`) + complete fn inventory via grep (`test_flush :533`,
`test_sync :605`, `test_dict_deflate :681`, `test_dict_inflate :743`,
`main :825`). Lines 501–914 HELD (not deep-read).

## Scope examined

zlib's own C test-suite port: `test_compress` (`:17`), `test_gzio` (`:56`),
`test_deflate` (`:199`), `test_inflate` (`:283`), `test_large_deflate`
(`:364`), `test_large_inflate` (`:463`), `test_flush` (`:533`),
`test_sync` (`:605`), `test_dict_deflate` (`:681`),
`test_dict_inflate` (`:743`), `main` (`:825`). Callers: none in-repo except
`build/zlib.w`, which compiles it to `bin/zlib_example` and runs it
(`foo.gz` fixture) in the batch-tier UAT (`:394+`).

## Behavioral matrix (EXECUTED vs HELD)

- EXECUTED `with check lib/std/zlib/example.w` → rc=0 (log at
  `docs/audit/probes/zlib_example/check.log`).
- HELD: `main` never run within batch budget — so `test_gzio` (the only
  in-repo exerciser of `gzprintf`/`gzseek`/`gzgetc`/`gzungetc`/`gzgets`),
  the dict tests, and the flush/sync tests are all unexecuted at module
  level. Conceptually overlapping probe coverage exists only for plain
  compress/uncompress/deflate/inflate (via the deflate probe's oracle-verified
  streams).

## Findings

None filed. In-report notes (not filed):
- Cross-reference for gzwrite F1: `test_gzio:83` calls
  `gzprintf(file, c", %s!".ptr, "hello")` — the same With-`str`-as-C-vararg
  shape present in the segfaulting probe. If F1 localizes to `gzprintf`,
  this suite would crash identically; running it (`with run` in
  `docs/audit/probes/zlib_example/` as cwd, it writes `foo.gz` locally) is the
  highest-value follow-up.
- Dict/flush/sync tests (`:533–824`) were inventoried, not read; their
  verdict weight is carried by the check + the engine's oracle evidence.

Verdict: INCOMPLETE
