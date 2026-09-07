# Primary verification — `lib/std/zlib/adler32.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 355 lines (two complete reads)

## Scope examined

Migrated adler32: `adler32` (`:16`, thin `c_uint` wrapper),
`adler32_z` (`:21`: len==1 fast path, null-buf→1, len<16 short loop,
NMAX=5552 16-wide unrolled blocks, 16-wide tail + remainder),
`adler32_combine`/`adler32_combine64` (`:301`/:306, both forward to
`adler32_combine_` `:311`, negative-len2→`0xffffffff`). Callers: engine
chain (`deflate`/`inflate`/`gz*` cross-import the module); no direct
user callers outside the engine.

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/zlib_adler32/probe.w` via
  `out/bootstrap/bin/with-stage1 run` (EXIT 0), oracles from CPython
  `zlib.adler32`: `adler32_z(1,"hello")==103547413`, wrapper matches,
  single-byte `"A"==4325442`, null-buf→1, streaming continuation
  `adler("hello ")+"world"==adler("hello world")==436929629`,
  `combine(140575285,111542825,5)==436929629` (+`combine64`,
  negative-len2→4294967295), 200-B `(i*31+7)%256` pattern==720986941,
  6000-B `i%256` pattern==1525910894 (forces the NMAX unrolled loop).
  All 8 `ok` lines present in `output.txt`. PASS.

## Findings

None. In-report notes (not filed):
- `adler32_z` with len==1 and a null buffer would dereference null —
  identical to C zlib (caller contract, not a migration regression).
- Thin wrappers `adler32`/`adler32_combine64` executed directly
  (no import collision in probe scope).

Verdict: COMPLETE
