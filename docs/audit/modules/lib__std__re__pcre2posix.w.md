# Primary verification — `lib/std/re/pcre2posix.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 411 lines (single complete read)

## Scope examined

POSIX wrapper over migrated PCRE2: `pcre2_regcomp` (`:20`), `pcre2_regexec`
(`:130`), `pcre2_regerror` (`:290`), `pcre2_regfree` (`:402`), plus `eint1`
(`:409`), `eint2` (`:410`), `pstring` (`:411`). Deps: `std.re.defs` (`regex_t`,
`regmatch_t`, `REG_*`), compile/match/context/substring/serialize/substitute/
jit/error/maketables modules, `std.libc`. Caller: `pcre2test.w` (`regcomp`
at `:10747`, `regexec` at `:15782`).

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_harness/probe_posix.w` (`with-stage1 run`, exit 0):
  `comp1=0 exec1=0 g0so=0 g0eo=4` (`a+b` vs `aaab`); `comp2=0 nsub=2 exec2=0
  q0=0 q0e=2 q1=0 q1e=1 q2=1 q2e=2` (`(a)(b)` captures); `comp3=0 exec3=0
  r3so=0 r3eo=3` (REG_ICASE `abc` vs `ABC`); `comp4=0 exec4=17` (REG_NOMATCH);
  `comp5=11 elen=26` (`(` → REG_EPAREN + message). All 5 byte-exact vs
  `python3 re` oracle (`(0,4)`, `(0,2)(0,1)(1,2)`, `(0,3)`, `None`,
  `missing ), unterminated subpattern`). PASS.
- Flag mapping audited literal-by-literal against `defs.w` constants and
  upstream `pcre2posix.c` (PCRE2Project 10.44 + 10.45, fetched): ICASE→8,
  NEWLINE→1024, DOTALL 16→32, NOSPEC 4096→33554432, UTF 64→524288,
  UCP 1024→131072, UNGREEDY 512→262144, NOTBOL→1, NOTEOL→2, NOTEMPTY→4;
  REG_PEND pointer-arithmetic patlen; UTF-error guard `rc<=-3,>=-23`→INVARG;
  9-arm match-error switch (`-63/-1/-32/-31/-34/-36/-47/-48/-51`, else ASSERT);
  `eint1` (24 entries), `eint2` (8 pairs incl. 98/102 — matches 10.45, not
  10.44), `pstring` (18). All identical to upstream. PASS.
- `with-stage1 check lib/std/re/pcre2posix.w` → exit 0. PASS.

## Findings

None. In-report notes (not filed):
- Style-only `redundant unsafe prefix inside unsafe context` warnings at
  `:403`/`:405` (`regfree`); pre-existing migrator output, no behavior impact.
- `REG_NOSUB` (32) handling (`:161–170`, forces nmatch=0) verified by read
  only; not covered by the probe (no negative-control run).

Verdict: COMPLETE
