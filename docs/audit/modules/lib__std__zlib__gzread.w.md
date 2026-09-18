# Primary verification — `lib/std/zlib/gzread.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 1246 lines (single complete read)

## Scope examined

Public read API: `gzread` (`:16`), `gzfread` (`:83`, size×nitems overflow
guard `:117`–`:130`), `gzgets` (`:146`, newline scan + NUL termination),
`gzgetc` (`:291`), `gzungetc` (`:352`, pushback incl. buffer-shift path
`:432`–`:448`), `gzdirect` (`:464`), `gzclose_r` (`:494`,
`inflateEnd` + buffer/close accounting), `gzgetc_` (`:553`). Internals:
`gz_load` (`:558`, EAGAIN/`again` handling), `gz_avail` (`:625`),
`gz_look` (`:686`, lazy alloc + `inflateInit2_(…, 15+16, …)` at `:726`,
gzip-magic sniff `:795`–`:811`, transparent-copy fallback), `gz_decomp`
(`:839`, `inflate` loop `:872` with corrupt-Data/Mem-mapping
`:880`–`:928`), `gz_fetch` (`:967`, how=0/1/2 dispatch),
`gz_skip` (`:1039`), `gz_read` (`:1103`). Deps: `inflate`
(`inflateInit2_/Reset/inflate/inflateEnd`), `gzlib` (`gz_error`,
`gz_intmax`), `deflate`/`compress`/`uncompr`/`gzwrite`/`gzclose`/`adler32`/
`crc32` (migrator-carried `use` lines). Callers: `minigzip.w:102`
(`gz_uncompress`), `example.w:105`.

## Behavioral matrix (EXECUTED vs HELD)

- `docs/audit/probes/zlib_gzread/main.w` — real gzip file produced by CPython
  `gzip.compress` (independent oracle, 4096-B payload): `gzopen(rb)` →
  chunked `gzread` (8 KiB requests) → byte-exact vs oracle payload
  (4096/4096 bytes, mismatch counter 0) → `gzclose_r == 0`. Exercises
  `gz_look` (magic sniff + `inflateInit2_`), `gz_fetch`/`gz_decomp`
  (`inflate` loop), `gz_read` copy-out, `gz_avail`/`gz_load` fd reads.
  ALL-PASS. EXECUTED.
- `test/behavior/behav_zlib_std.w` gzip cases (same engine family via
  facade) → `ok`. EXECUTED (corroborating).
- `with check lib/std/zlib/gzread.w` → exit 0 (stage1). EXECUTED.
- `gzfread`/`gzgets`/`gzgetc`/`gzungetc`/`gzdirect` line paths: read in
  full; `gzdirect` additionally EXECUTED via the gzlib probe (returns 0
  for a gzip member). Remainder HELD (no divergence spotted; buffer
  arithmetic mirrors the canonical implementation).

Caveat: `run` probes link the stage1-embedded stdlib copy; working-tree
sources verified by full read plus the check above.

## Findings

None. In-report notes (not filed):
- `gz_load` treats only errno 35 (`EAGAIN`) as retryable (`:593`–`:600`,
  duplicated comparison); blocking fds are the norm for this API, so a
  missed `EINTR` retry would surface as a loud `-1`, never silent data
  corruption.

Verdict: COMPLETE
