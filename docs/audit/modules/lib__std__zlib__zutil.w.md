# Primary verification — `lib/std/zlib/zutil.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 153 lines (single complete read)

## Scope examined

Migrated zutil: `zlibVersion` (`:16`, returns `"1.3.2"`),
`zlibCompileFlags` (`:21`, sizeof-gated bitmask), `zError` (`:110`,
`z_errmsg[2-err]` with out-of-range→`""` fallback), `zcalloc`
(`:132`, `with_alloc` when `sizeof[c_uint]>2` else
`with_alloc_zeroed`), `zcfree` (`:148`, `with_free`). Callers:
engine chain (allocators/versions wired into deflate/inflate
streams); `zlib_version` in `defs.w:487` (see defs F1).

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/zlib_zutil/probe.w` via
  `out/bootstrap/bin/with-stage1 run` (EXIT 0), oracles from C zlib
  semantics: `strcmp(zlibVersion(),"1.3.2")==0`,
  `zlibCompileFlags()==169` (LP64: 1+8+32+128, derived from the
  branch structure, asserted at runtime), `zError` strings for
  1/−2/−3/−4/−5/−6 match the `z_errmsg` table and 99/−99 fall back
  to `""`, `zcalloc` returns usable memory (write+read-back 42)
  released by `zcfree`. All 4 `ok` lines in `output.txt`. PASS.

## Findings

None. In-report notes (not filed):
- `zcalloc` using non-zeroed `with_alloc` on LP64 mirrors C
  `zutil.c`'s `sizeof(uInt) > 2 ? malloc : calloc` selection — the
  branch structure is a faithful port, and no caller in the engine
  relies on zeroed memory (streams initialize all fields).

Verdict: COMPLETE
