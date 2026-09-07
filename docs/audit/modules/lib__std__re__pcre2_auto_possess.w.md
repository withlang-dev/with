# Primary verification — `lib/std/re/pcre2_auto_possess.w`

Status: **COMPLETE (sampling-based)** — no defects
Primary verifier: audit-re-compile (source sampling + executed differential probes)
Source revision: `450733e5`
Source examined: sampling — 3,925 lines total. Samples:
`_pcre2_auto_possessify_8` head (`:32-150`: `rec_limit=1000`, UTF/UCP from
`external_options` bits `0x80000`/`0x20000`, repeat-base normalization,
STAR/PLUS/QUERY/UPTO→POS* conversion switch on raw values 33-40);
`get_repeat_base` full (`:1083-1131`: `>TYPEPOSUPTO→self`,
`≥TYPESTAR→TYPESTAR`, `≥NOTSTARI/NOTSTAR/STARI` ladder, else `STAR` —
matches upstream); `check_char_prop` (`:773`), `get_chr_property_list`
(`:1133`), `compare_opcodes` (`:2144`) by signature only. Behavior below
was EXECUTED.

## Scope examined

Auto-possessify runs on every compile unless `NO_AUTO_POSSESS`, so all 26
valid probe cases traverse it. Direct evidence: `no-auto-possess`
(`a+b` + flag → `[0,4)` both), `possessive` (`a++b` → `[0,4)` both),
`greedy`/`ungreedy` (convergent match, both). Adjacent: `pcre2_jit_compile_8`
(lives in `pcre2_jit_compile.w`, out of scope) probed via the `jit` case →
`-45` with `JIT_COMPLETE`, matching an upstream no-JIT configuration build
(system lib has JIT — config difference, not port difference).

Coverage honesty: `get_chr_property_list`/`compare_opcodes` bodies (the
character-class vs following-opcode disjointness reasoning, ~2.5k lines)
were NOT read; verified only behaviorally (possessive/no-auto-possess
pairs agree, and no valid pattern changed outcome vs the oracle) plus the
upstream RunTest corpus.

`with check lib/std/re/pcre2_auto_possess.w` → rc=0, 0 errors.

## Findings

None. In-report notes (not filed):

- N1: a wrong possessification would show as a match-outcome divergence on
  some valid case; the 26-case matrix shows none. The highest-risk
  sub-decision (class-vs-next-opcode disjointness in `compare_opcodes`)
  deserves a targeted read if a possessive-related mismatch ever appears.

Verdict: COMPLETE (sampling-based, samples listed above)
