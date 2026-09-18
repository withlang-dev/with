# Primary verification — `lib/std/zlib/compress.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 202 lines (two complete reads)

## Scope examined

Migrated one-shot compressor: `compress`/`compress_z` (`:15`/:20,
forward to `compress2[_z]` with level −1), `compress2`/`compress2_z`
(`:25`/:38: null/empty validation→−2, `deflateInit_` with
`"1.3.2"`, `UINT_MAX`-quantum feed loop, `Z_FINISH` on drained
input, `STREAM_END`→`Z_OK` mapping), `compressBound`/
`compressBound_z` (`:172`/:188: `len+len>>12+len>>14+len>>25+13`
with wraparound→`0xffffffffffffffff` guard). Callers: facade
`compress_level` (`lib/std/zlib.w:55`); engine-internal.

## Behavioral matrix (EXECUTED vs HELD, oracles independent)

EXECUTED — `docs/audit/probes/zlib_compress/probe.w` via
`out/bootstrap/bin/with-stage1 run` (EXIT 0):
`compressBound(38/0/1000)==51/13/1013` (formula values, the 38-case
cross-checked against CPython's bound arithmetic),
`compress2`(−1) deflates 200 B, `uncompress` restores it byte-exact,
levels 1–9 all encode+decode, level 10→−2 (`Z_STREAM_ERROR`),
2-B dest→−5 (`Z_BUF_ERROR`). All 6 `ok` lines in `output.txt`. PASS.
HELD — thin forwarders `compress`/`compress_z` not invoked directly
(their exact bodies were read; both are single-line delegations to
the fully-executed `compress2`/`compress2_z`, and the facade probe
covers the same delegation shape through `compress2`).

## Findings

None.

Verdict: COMPLETE
