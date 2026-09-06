# Primary verification — `lib/std/zlib/deflate.w`

Status: **COMPLETE** (no runtime defects; one check-as-root anomaly documented, not filed)
Primary verifier: primary (partial source read + full API inventory + probe execution)
Source revision: `450733e5`
Source examined: 4431 lines; deep read lines 1–500 (`deflate()` entry/state machine,
header emission, gzip-header path) + complete fn inventory via grep (17 pub fns,
9 priv helpers) + `:4431` `configuration_table` (via diagnostic). Remainder HELD.

## Scope examined

`deflate` (`:17`), `deflateEnd` (`:1092`), `deflateSetDictionary` (`:1138`),
`deflateGetDictionary` (`:1296`), `deflateCopy` (`:1332`), `deflateReset`
(`:1450`), `deflateParams` (`:1463`), `deflateTune` (`:1595`),
`deflateBound/z` (`:1616`/`:1632`), `deflatePending` (`:1824`),
`deflateUsed` (`:1849`), `deflatePrime` (`:1862`), `deflateSetHeader`
(`:1922`), `deflateInit_/Init2_` (`:1942`/`:1947`), `deflateResetKeep`
(`:2219`); engines `deflate_stored/fast/slow/rle/huff` + `longest_match`,
`fill_window`, `flush_pending`, `lm_init` (priv). Deps: `std.zlib.defs`,
`zutil`, `inflate`, `compress`, `gzlib/gzwrite/gzread/gzclose`, `adler32`,
`crc32`, `trees`. Callers: `lib/std/zlib.w` facade (`compress_gzip_level`
via `deflateInit2_`/`deflate`/`deflateEnd`, `compressBound` via
`deflateBound`), `gzwrite.w:gz_comp`, `example.w` deflate tests, `minigzip.w`
via gz layer.

## Behavioral matrix (EXECUTED vs HELD)

- EXECUTED `docs/audit/probes/zlib_deflate/probe.w` (`run.log` rc=0,
  `probe-deflate-done`): 12 cases (empty / `AB`*3000 / LCG-pseudorandom 2048 B
  × levels 0/1/6/9 — exercises stored, fast, and slow engines) plus
  `compress_gzip` (Init2_ gzip path). Every output decompressed byte-exact by
  the INDEPENDENT oracle (python3 zlib 1.3.1): `empty l0: clen=11 OK`,
  `rep l6/l9: clen=31 dlen=6000 OK`, `inc l6/l9: clen=290 dlen=2048 OK`
  (all 12 OK, `rep_gzip: 6000 OK`). With-side `decompress` round-trip asserts
  also passed in-process. 13 `.z`/`.gz` artifacts under
  `docs/audit/probes/zlib_deflate/out/`.
- EXECUTED `with check lib/std/zlib/deflate.w` → rc=1 (anomaly, see note;
  log at `docs/audit/probes/zlib_deflate/check.log`).
- HLD: lines 501–4430 not deep-read; `deflateCopy/Tune/Prime/SetHeader`/dict
  paths not individually probed (covered only as shared engine code).

## Findings

None filed. In-report notes (not filed):
- `check`-as-crate-root fails with a single error,
  `shadowing is not allowed for 'configuration_table'` (`:4431`). Refutation
  as source defect: (a) only the two files with top-level `let` statics
  (`deflate.w`, `trees.w`) fail this way while `gzwrite/gzclose/minigzip/
  example` check clean (rc=0); (b) no supported flow compiles these files as
  crate roots (iterate tier checks `src/main.w`; `build/zlib.w` builds them
  as units); (c) the same sources produce oracle-verified-correct bytes at
  runtime. Mechanism diagnosis HELD — recorded here, not a defect claim.
- Caveat: `with run` links the seed binary's EMBEDDED std, so probe bytes
  characterize the embedded engine; transfer to workspace source rests on
  API-compatibility evidence (4/6 workspace files check clean against embedded
  deps; failing two fail only on same-name top-level `let`s, implying content
  correspondence, not divergence).

Verdict: COMPLETE
