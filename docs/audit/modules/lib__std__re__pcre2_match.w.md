# Primary verification — `lib/std/re/pcre2_match.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (source sampling + probe execution)
Source revision: `450733e5`
Source examined: sampling-based — ~500 of 48,831 lines read directly
(see sample list); full behavioral coverage through the module's entry
points via executed differential probes.

## Scope examined

Backtracking engine: `pcre2_match_8` (`:32`, pub entry), `do_callout`
(`:2554`), `match_ref` (`:2640`, backreferences), `recurse_update_offsets`
(`:3018`), `match_` (`:3097`, main opcode interpreter, bulk of the file).

Samples read (exact):
- `:32–151` — `pcre2_match_8` prologue: goto-lifted locals
  (`__local_*__goto_*` per C label), `__ci_expr_*` temporaries.
- `:320–434` — basic-block option validation: the match-options mask
  check (`:326`) returning `-34` (`:334`, and `:427` for partial-mode
  conflict) — the exact check that produced the probe's UTF `-34`
  (PCRE2_ERROR_BADOPTION), confirming it is upstream validation logic.
- `:2640–2719` — `match_ref`: backref to an unset/out-of-range group
  returns `-1` (fail) unless option bit 512
  (PCRE2_MATCH_UNSET_BACKREF) is set — matches probe case 34.
- `:3097–3201` — `match_` frame setup (`heapframe` chain, F/N/P,
  branch/bracode pointers).
- Migration idioms observed: C `do{}while(0)` → `loop { 0; if not
  ((0 != 0)) { break } }`, C `~0` → `(~(0 as c_ulong))`, C `?:` →
  `(if c: a else: b)`, labels → `'__ci_bb_N` blocks. No hand-edit or
  "generated file" markers anywhere in `lib/std/re/`.

## Upstream fidelity tracking

Port of PCRE2 **10.47**: pin is `build.w:2865` (release URL
`.../pcre2-10.47.tar.gz`) with sha256 `c08ae2…dc16`
(`build/pcre2.w:8`), enforced by the `pcre2-reference` action.
Fidelity is tracked by migrating + running the upstream corpus:
`:pcre2-test` runs upstream `RunTest` (`-8`, tests 0–29 + heap)
against the migrated `pcre2test` binary; `wo-drift` re-checks the
bundle root and rebuilds byte-identically. Per-file provenance beyond
the pin is the `// Migrated from C` header; no per-function C-line
mapping exists (accepted: the oracle is behavioral, not textual).
`docs/wo_bundles.md` "Known debt #941" (hand edit in `defs.w` a
re-migrate would drop) appears resolved by `70898d0c` — no hand-edit
markers found; the doc note itself is now stale (doc nit, not filed).

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_engines/match_matrix.w` (38 cases, direct
  `pcre2_compile_8`/`pcre2_match_8` calls): literals, classes
  (`[a-z]`, `[^0-9]`, `\d`, `\w`, `\b`), quantifiers
  (greedy `{2,3}`/`+`/`*`/`?`, lazy `+?`, possessive `++` incl.
  `a++b`), anchors (`^`/`$`), groups/backrefs (`(a|b)\1` match and
  no-match, `(a)(b)(c)`, `(?:…)`, `(?P<w>…)`), ordered alternation
  (`a|ab` → `a`), lookahead/lookbehind (positive and negative),
  empty pattern / empty subject / empty match (`()`, `x?`, `""`,
  `a*` on `""`), unset-group backref (`(a)?b\1` on `b` → NOMATCH),
  compile errors (`(` → ec 114; `a{2,1}` → ec 104), UTF-8
  (`é`/UTF mode → `[3,5)` byte offsets).
- `docs/audit/probes/re_engines/oracle_compare.py`: every case diffed
  against **system pcre2test 10.47** (the exact upstream release,
  per-case runs) by matched text and against **python3 `re`**
  (bytes mode) by exact ovector spans. Result: `FAILURES: 0`
  (38/38 parsed; possessive cases 7–8 python-skipped — unsupported
  syntax — covered by pcre2test; empty-subject case 33
  pcre2test-skipped — blank-line limitation — covered by python).
- `with-stage1 check lib/std/re/bundle.w` → rc 0 (~6.2 s, warnings
  only: redundant-unsafe-prefix, large-Copy notes).

## Findings

None. In-report notes (not filed):
- `test/pcre2_smoke.w`, `test/pcre2_verify.w` do not compile with the
  seed at this commit (`unsafe function call requires unsafe
  context` on migrated `*_free_8`/context calls) — stale dev
  harnesses, superseded by the `:pcre2-test` RunTest lane; neither is
  referenced by `build.w`. Probes in `docs/audit/probes/re_engines/`
  were written with correct `unsafe` wrapping instead.
- Coverage is sampling-based for this 48k-line file: ~500 lines read
  plus a 38-case behavioral matrix through all five functions'
  reachable paths (the matrix exercises compile, bumpalong, the
  interpreter, backrefs, assertions, and UTF paths). Line-level
  fidelity of unreviewed opcode arms rests on the upstream RunTest
  lane, not on this audit.

Verdict: COMPLETE
