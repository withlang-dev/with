# Primary verification — `lib/std/zlib/crc32.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read of entry/combine/table
regions + probe execution; see HELD)
Source revision: `450733e5`
Source examined: `:1–200` (entry `crc32`/`crc32_z`, LE braid fast path),
`:345–490` (`crc32_combine_op`/`crc32_combine`/`crc32_combine_gen`/
`get_crc_table`/`crc32_combine64`/`crc32_combine_gen64`, `multmodp`,
`x2nmodp`, `crc_word`, tables `crc_table`/`crc_big_table`/
`crc_braid_table`/`crc_braid_big_table`), fully read; `:200–344`
(BE braid path, `byte_swap` plumbing) read in part — HELD below.

## Scope examined

Migrated crc32: `crc32` (`:16`, thin `c_uint` wrapper), `crc32_z`
(`:21`: null-buf→0, byte-at-a-time align prologue, 5-way slicing
braid for len≥47 LE / byte-swapped BE variant, `crc_word` tail),
`crc32_combine*`/`crc32_combine_gen*`/`crc32_combine_op`
(`:345–:379`, GF(2) combine via `x2nmodp`/`multmodp`),
`get_crc_table` (`:364`). Callers: engine chain only.

## Behavioral matrix (EXECUTED vs HELD, oracles independent)

EXECUTED — `docs/audit/probes/zlib_crc32/probe.w` via
`out/bootstrap/bin/with-stage1 run` (EXIT 0), oracles from CPython
`zlib.crc32`: `crc32_z(0,"hello")==907060870`, wrapper matches,
null-buf→0, `"123456789"==3421780262` (standard check value),
streaming `crc("hello ")+"world"==crc("hello world")==222957957`,
`combine(3984718326,980881731,5)==222957957` (+`combine64`,
`gen`→`op` round trip), `get_crc_table()[1]==1996959894`,
200-B pattern==315481199 (exercises the LE braid), 6000-B
pattern==4134842720 (multi-block braid). All 9 `ok` lines in
`output.txt`. PASS. (`combine` passing also behaviorally covers
`x2nmodp`/`multmodp` on this host.)
HELD — big-endian braid branch + `crc_braid_big_table` contents:
unreachable on little-endian hosts (this machine), no BE hardware
available to execute; tables spot-checked by shape only. No BE-only
logic was modified by the migration (straight-line port).

## Findings

None.

Verdict: COMPLETE
