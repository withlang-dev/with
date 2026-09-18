# Primary verification — `lib/std/re/defs.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-re-support (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 3720 lines — helpers/externs/types/constants/default
tables read directly (`:1-2758`, `:3690-3720`); the giant numeric data
blocks (`_pcre2_stage2_8` 40320-entry table, ucd_records tail, ucd stage
tables) spot-checked at head/tail and verified behaviorally instead.

## Scope examined

Foundation module: `print_i32`/`with_alloc`/`with_free`/`with_memcpy`
externs, `c_*` aliases, `pchar`/`spchar`, all PCRE2 option/info/config/
error/JIT/substitute/convert tables constants (`:138-`, cross-checked vs
`/usr/include/pcre2.h`: `PCRE2_UTF=0x80000`, `PCRE2_ERROR_NOMATCH=-1`,
`PCRE2_INFO_CAPTURECOUNT=4`, `PCRE2_CONFIG_VERSION=11`,
`PCRE2_SUBSTITUTE_GLOBAL=0x100`, `PCRE2_CONVERT_GLOB=0x10`,
`PCRE2_ALT_EXTENDED_CLASS=0x08000000`, `PCRE2_CONFIG_JIT=1`,
`PCRE2_CONFIG_JITTARGET=2` — all match), OP_* opcodes (`OP_END=0`,
`OP_XCLASS=112`, `OP_TABLE_LENGTH=173`), `pcre2_real_code_8` (152 B),
`pcre2_real_match_data_8` (~1 MB ovector), `compile_block_8`,
`pcre2_memctl`, `match_block_8`/`heapframe`, `_pcre2_default_tables_8`
(1088 B: lcc/fcc/cbits/ctypes), default compile/match/convert contexts,
POSIX states, META tokens, ERR codes, option masks, eclass/verb/posix/
cmd/mod/patctl/datctl harness types. Callers: every re module.

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_support/r1_misc.w` via
  `out/bootstrap/bin/with-stage1 run` (exit 0):
  `nomatch=-1 utf=524288 infocap=4 cfgver=11 subglob=256 convglob=16`,
  `tableslen=1088 ucpLu=9 ucpNd=13 maxtables=1114111`,
  `op_end=0 op_xclass=112 op_tablelen=173` — all match the system header.
  Full output in `docs/audit/probes/re_support/output_r1.txt`.
- Default tables content: `maketables_bad=0` (fresh
  `pcre2_maketables_8(null)` byte-identical to `_pcre2_default_tables_8`
  over all 1088 bytes), `lccA=97` (`lcc['A']='a'`), `fcct=84`
  (`fcc['t']='T'`). PASS.
- `with-stage1 check lib/std/re/defs.w` → exit 1, `error: undefined
  variable` for `default_malloc`/`default_free` at `:2763` — these live in
  `pcre2_context.w` (`:512-524`), so standalone check cannot resolve them.
  Harness artifact, not a defect: `with-stage1 check
  lib/std/re/bundle.w` → `ok` (exit 0), and every probe composing
  `defs+context` runs clean.

## Findings

None. In-report notes (not filed):
- Standalone-check failure above (use-graph artifact; bundle is green).
- `with check` emits large-`Copy` warnings for the 1 MB match-data frame
  types — pre-existing style lint, no behavior impact.

Verdict: COMPLETE
