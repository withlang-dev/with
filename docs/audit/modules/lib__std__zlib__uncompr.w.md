# Primary verification — `lib/std/zlib/uncompr.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 223 lines (two complete reads)

## Scope examined

Migrated one-shot decompressor: `uncompress`/`uncompress_z`
(`:15`/:22, forward to `uncompress2[_z]` with full-length `used`),
`uncompress2` (`:29`, `c_ulong` adapter), `uncompress2_z` (`:47`:
null/empty validation→−2, `inflateInit_` with `"1.3.2"`,
`UINT_MAX`-quantum feed loop, `STREAM_END`→0 /
`NEED_DICT`-as-2→−3 / trailing-`BUF_ERROR`-with-empty-input→−3
mapping, `*sourceLen`/`*destLen` usage reporting). Callers:
facade indirectly (facade uses its own `zlib_inflate_to_buffer`,
not this module); engine-internal and parity surface for C zlib.

## Behavioral matrix (EXECUTED vs HELD, oracles independent)

EXECUTED — `docs/audit/probes/zlib_uncompr/probe.w` via
`out/bootstrap/bin/with-stage1 run` (EXIT 0), oracle = CPython
`zlib.compress` bytes: 26-B python stream decodes to the exact 39-B
original, `uncompress2` reports `dlen==39`/`used==26`, plaintext
input→−3 (`Z_DATA_ERROR`), 1-B dest→−5 (`Z_BUF_ERROR`). All 4 `ok`
lines in `output.txt`. PASS.
HELD — thin forwarders `uncompress_z`/`uncompress2_z` not invoked
directly (single-line delegations, bodies read; delegated targets
fully executed).

## Findings

None. In-report notes (not filed):
- The `local_dest` null-guard branch (`:107–116`, zero-length output
  with null dest) was read but not executed — it requires a
  null-dest call the safe facade never makes; direct unsafe probing
  would exercise UB-adjacent contract corners with no behavioral
  signal beyond the already-pinned codes.

Verdict: COMPLETE
