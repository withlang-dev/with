# Primary verification — `lib/std/zlib/gzlib.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 842 lines (single complete read)

## Scope examined

File-handle lifecycle: `gz_open` (`:614`, mode-string parser `:659`–
`:726` incl. `+`-reject `:680`–`:684`, `G`/`T` direct-mode rules
`:735`–`:754`, `O_EXCL`/append handling, fd vs path open `:798`–`:811`,
read-start capture `:829`–`:836), `gzopen` (`:235`), `gzopen64`
(`:294`), `gzdopen` (`:16`, `<fd:%d>` pseudo-path), `gz_reset` (`:586`),
`gz_error` (`:530`, message ownership incl. `-4` static-string rule),
`gzbuffer` (`:47`, pre-allocation-only + overflow guard `:72`),
`gzrewind` (`:86`), `gzeof` (`:125`), `gzerror` (`:158`),
`gzclearerr` (`:204`), `gzseek`/`gzseek64` (`:240`/`299`, SEEK_SET/CUR,
direct-skip vs rewind-and-discard `:402`–`:417`), `gztell`/`gztell64`
(`:258`/:461), `gzoffset`/`gzoffset64` (`:276`/:494), `gz_intmax`
(`:581`). Deps: `gzread` (`gz_reset`), `inflate`/`infback`/`deflate`
(migrator-carried `use` lines), `std.libc`. Callers: `gzread.w`
(`gz_open` consumers), `gzwrite.w`, `minigzip.w`, `example.w`.

## Behavioral matrix (EXECUTED vs HELD)

- `docs/audit/probes/zlib_gzlib/main.w` — against a CPython-`gzip` file
  (independent oracle): `gzopen(rb)` non-null, `gzeof == 0` before EOF,
  `gzerror` message non-null, `gzdirect == 0` for a real gzip member,
  `gzclose_r == 0`, `gzopen` of a missing path returns null. ALL-PASS
  (6/6). EXECUTED.
- `docs/audit/probes/zlib_gzread/main.w` open/read/close leg of the same
  file (covers `gz_open` read-mode branch + `gz_reset`) — ALL-PASS.
  EXECUTED (corroborating).
- `with check lib/std/zlib/gzlib.w` → exit 0 (stage1). EXECUTED.
- Write/append/seek/tell/offset branches (`gzseek64` skip vs rewind
  paths, `gzdopen`, `gzbuffer`): read in full, no anomaly; not driven
  (no write-side fixture in this audit). HELD.

Caveat: `run` probes link the stage1-embedded stdlib copy; working-tree
sources verified by full read plus the check above.

## Findings

None. In-report notes (not filed):
- `gzseek`/`gztell`/`gzoffset` wrap their 64-bit twins behind a
  tautological `__local_ret == __local_ret` NaN-style guard
  (`:247`,`:264`,`:281`) — dead but harmless; upstream-shaped behavior
  is preserved bit-for-bit.

Verdict: COMPLETE
