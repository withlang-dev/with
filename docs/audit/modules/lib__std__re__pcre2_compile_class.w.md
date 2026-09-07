# Primary verification — `lib/std/re/pcre2_compile_class.w`

Status: **COMPLETE (sampling-based)** — no defects
Primary verifier: audit-re-compile (source sampling + executed differential probes)
Source revision: `450733e5`
Source examined: sampling — 5,040 lines total. Full-function reads: none;
samples: `_pcre2_update_classbits_8` head (`:34-113`), nested-class entry
`_pcre2_compile_class_nested_8` head (`:2325-2384`); all 23 function
signatures enumerated (`:34-4927`). Behavior below was EXECUTED.

## Scope examined

Class-bitmap path: `PT_CLIST` (ptype 13) → 32-byte memset-all (`:47-54`);
UCD two-stage lookup `stage1[c/128]*128 + c%128` (`:59`); ptype dispatch
0=letter-any (Lu/Ll/Lt, `:67-89`), 1=general-category (`:91`), 2=script
(`:94`), 3=script-extended with `scriptx` set test (`:102-108`). Nested
(extended-class) path: `eclass_context` init, `OP_ECLASS` emit byte 113,
delegation to `compile_eclass_nested`, length accounting (`:2374-2383`).
Remaining surface (`_pcre2_compile_class_not_nested_8`, `parse_class`,
`compile_optimize_class`, `add_to_class`, `fold_negation`/`fold_binary`,
`compile_class_{operand,juxtaposition,unary,binary_tight,binary_loose}`,
`get_nocase_range`, `utf_caseless_extend`, heapify) cited by signature only.

Coverage honesty: inner class-emit loops were NOT read line-by-line;
verified behaviorally (matrix below) and via the upstream RunTest corpus
(`build/pcre2.w` `:pcre2-verify`, testdata classes 1-30+).

## Behavioral matrix (all EXECUTED; full matrix in
[compile report](lib__std__re__pcre2_compile.w.md))

Class-exercising cases from `docs/audit/probes/re_compile/probe_output.txt`
(vs pcre2test 10.47, all agree): `ci-class` (`[a-z]+` caseless on `HELLO`
→ `[0,5)`), `ucp`/`noucp` (`\w+` on `é` → `[0,1)` on both — non-UTF
single-byte semantics identical), `allow-empty-class` (`[]b` compiles,
never matches — both), `noallow-empty-class` (FAIL 106@3 both),
`bad-class` (`[abc` → 106@4 both), `bad-bigrange` (`[z-a]` → 108@4 both).
Prior fuzz re-run (`prior_fuzz_output.txt`, 30/30 vs `oracle_percase.txt`):
`class`, `negclass`, `posixclass` (`[[:alpha:]]+` → `[0,5)`) match with exact
spans. `with check lib/std/re/pcre2_compile_class.w` → rc=0, 0 errors.

## Findings

None. In-report notes (not filed):

- N1: `get_nocase_range`/`utf_caseless_extend`/`append_negated_char_list`
  (caseless range expansion, `:2731-3081`) verified only through the
  `ci-class` behavioral case, not by reading. Turkish-casing extras
  (`EXTRA_TURKISH_CASING`) untouched by any probe — upstream-corpus-only
  coverage.

Verdict: COMPLETE (sampling-based, samples listed above)
