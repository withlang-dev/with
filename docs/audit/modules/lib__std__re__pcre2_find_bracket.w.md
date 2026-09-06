# Primary verification — `lib/std/re/pcre2_find_bracket.w`

Status: **COMPLETE (sampling-based)** — no defects
Primary verifier: audit-re-compile (full read + executed differential probes
+ opcode cross-check)
Source revision: `450733e5`
Source examined: **all 612 lines** (`:1-612`, full read of the single
function `_pcre2_find_bracket_8`). Behavior below was EXECUTED.

## Scope examined

Loop-over-compiled-code structure, verified arm by arm: `OP_END` → null
(`:37`); `OP_XCLASS`/`OP_ECLASS` length-skip (`:49`); `OP_CALLOUT_STR` skip
(`:52`); `OP_REVERSE`/`OP_VREVERSE` return-or-skip (`:63`); CBRA-family
number match (`:95-102`); per-opcode extra adjustments; `OP_lengths` advance
(`:310`); UTF extra-byte adjustment via `utf8_table4` (`:312-599`).

Fidelity cross-check (no upstream tree in repo): every raw `match` number
decoded against `defs.w` opcode values. Switch 1 = exactly the 13 `TYPE*`
opcodes (PROP/NOTPROP subtype check; `UPTO`/`EXACT` variants read the
subtype at offset 3 = 1+2, matching their 2 extra min/max bytes) plus the
5 `MARK`/`PRUNE_ARG`/`SKIP_ARG`/`THEN_ARG`/`COMMIT_ARG` ops (`code +=
code[1]`). Switch 2 (UTF) = exactly the 56 single-character opcodes
(`CHAR/CHARI/NOT/NOTI` + STAR/PLUS/QUERY/UPTO/EXACT/MIN/POS/NOT ×
plain/`I`). Sets are complete and disjoint — no missing or stray arm.
`_pcre2_OP_lengths_8` table present (`defs.w:2200`, 173 entries).

Live caller: `pcre2_compile.w:1719` (group search for numeric backrefs),
so every backref compile exercises it.

## Behavioral matrix (all EXECUTED; full matrix in
[compile report](lib__std__re__pcre2_compile.w.md))

Backref/group cases from `docs/audit/probes/re_compile/probe_output.txt`:
`bad-backref` (115@5 both), `dupnames-ok` (rc=3). Prior fuzz re-run
(`prior_fuzz_output.txt`, 30/30 vs `oracle_percase.txt`): `nested`
(rc=5, exact spans), `backref-hit`/`backref-miss`, `lookbehind`.
`with check lib/std/re/pcre2_find_bracket.w` → rc=0, 0 errors.

## Findings

None.

Verdict: COMPLETE (full read + probes + opcode cross-check)
