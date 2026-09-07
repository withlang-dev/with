# Primary verification — `lib/std/re/pcre2_substitute.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-re-support (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 5386 lines — entry validation (`:32-361`) and all
three tail helpers fully read (`find_text_end` `:4196-`, `read_name_
subst`, `pessimistic_case_inflation`, `default_substitute_case_callout`
exact `UL→upper/L→lower` copy loops, `do_case_copy`); the main
`pcre2_substitute_8` replacement engine (`:361-4195`, goto-lowered)
surveyed structurally (all error exits inventoried: -43/-48/-49/-51/
-55/-60/-61/-63 paths) and verified behaviorally below.

## Scope examined

Entry: code/subject/replacement/ovector null checks, option-mask
validation (only KNOWN bits; `REPLACEMENT_ONLY`/`LITERAL` value
constraint), UTF/UCP/UNSET flags from code extras, ovector sizing vs
`top_bracket`, `startchar` reset, overflow-length preflight
(-63 BADSUBSTITUTION when the replacement provably cannot fit).
Engine: global iteration, `$`/`$n`/`${n}` expansion, case forcing
`\L\U\E\L..\E`, `*MARK`/`*:` verbs, unknown/unset-name policy matrix
(UNKNOWN_UNSET vs UNSET_EMPTY vs default -55), literal mode, callout
hook. Helpers: `find_text_end` (case-run scanner),
`pessimistic_case_inflation` (2×/3× UTF upper-bound sizing),
`default_substitute_case_callout` + `do_case_copy` (ASCII fast path,
single-char UTF slow path with ` Forder` recode).

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_support/r5_substitute.w` (`output_r5.txt`):
  `swap-global rc=2 blen=19 out=world hello bar foo` (== pcre2test AND
  python `re.sub`),
  `lower-second rc=1 blen=11 out=world Hello` (== pcre2test
  `substitute_extended`),
  `unset-empty rc=1 blen=8 out=[aaa][b]`,
  `unset-default rc=1 blen=8 out=[aaa][b]`,
  `single rc=1 blen=4 out=heLo` (== python),
  `literal rc=1 blen=4 out=<$1>`,
  `unset-err rc=-55 blen=7` / `unset-ok rc=1 blen=7 out=[aaa][]`.
  The last pair was cross-checked against a direct C oracle
  (`cc … -lpcre2-8`): C prints `default rc=-55 blen=7` and
  `unsetempty rc=1 blen=7 out=[aaa][]` — byte-exact agreement
  (pcre2test's `Bad buffer size` message on these two cases is its own
  harness-buffer artifact). PASS.
- `with-stage1 check lib/std/re/pcre2_substitute.w` → `ok` (exit 0).

## Findings

None. In-report notes (not filed):
- The main engine's goto body was verified behaviorally (8 substitution
  shapes + C-oracle pair), not arm-by-arm; entry + helpers + error-exit
  inventory were read fully.

Verdict: COMPLETE
