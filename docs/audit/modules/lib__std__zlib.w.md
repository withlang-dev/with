# Primary verification — `lib/std/zlib.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 168 lines (single complete read)

## Scope examined

Safe in-memory facade over the migrated engine: `ZlibError` (`:13`),
`compress`/`compress_level` (`:45`/:48), `compress_gzip`/`compress_gzip_level`
(`:63`/:66), `decompress`/`decompress_with_limit` (`:100`/:103),
`decompress_gzip`/`decompress_gzip_with_limit` (`:106`/:109),
`decompress_window_bits` (`:112`, growable output capped by
`ZLIB_DEFAULT_MAX_OUTPUT`), `zlib_inflate_to_buffer` (`:139`, chunked
inflate with `UINT_MAX` feed quanta, `Z_NEED_DICT`→`Z_DATA_ERROR` mapping).
Callers: `test/behavior/behav_zlib_std.w` (round-trip/gzip/errors),
`lib/std/build.w:2220` (emits `use std.zlib` into the gunzip helper),
`build/zlib_gzip.w`, `build/release_uat_fixtures/zlib_main.w` (via C
`#include`, not this facade). `build/zlib_gunzip.w` uses
`std.zlib.defs`+`inflate` directly, bypassing the facade.

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/zlib_facade/probe.w` via
  `out/bootstrap/bin/with-stage1 run` (EXIT 0): zlib round-trip,
  gzip round-trip with `1f 8b` magic asserted, levels 1/9, empty
  input (`compress`→`decompress`→empty), 8 error cases
  (level 10, level −2, decompress-plaintext, decompress-empty,
  limit 1, limit −1, gzip-of-zlib-bytes, zlib-of-gzip-bytes — all Err).
  All `ok` lines present in `output.txt`. PASS.
- python3→With: `zlib.compress` (26 B) and `compressobj(wbits=31)`
  gzip (38 B) fixtures embedded as byte literals decode to the exact
  39-B fixture text. PASS.
- With→python3 (`reverse_interop.txt`): With-produced zlib bytes
  decompress under CPython `zlib` to the fixture text, With-produced
  gzip bytes under CPython `gzip` likewise — and the With zlib bytes
  are **byte-identical** to CPython `zlib.compress` output (26/26).
  PASS (encoder behaviorally identical to C zlib at default level).

## Findings

None. In-report notes (not filed):
- Cross-format rejection pins the window-bits routing: gzip bytes fail
  `decompress` (wbits 15) and zlib bytes fail `decompress_gzip`
  (wbits 31) — no silent mis-decode.
- `decompress` of empty input is Err (inflate yields BUF→DATA error);
  `compress` of empty input is Ok and round-trips.

Verdict: COMPLETE
