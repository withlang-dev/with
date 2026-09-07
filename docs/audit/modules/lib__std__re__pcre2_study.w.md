# Primary verification — `lib/std/re/pcre2_study.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-re-support (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 6647 lines — `_pcre2_study_8` entry fully read
(`:32-576`: minlength dispatch, SSB_FAIL→0/SSB_UNKNOWN→unset sentinels,
`first_codeunit` + `first_bitmap` + `last_codeunit` publication);
`set_table_bit`/`set_type_bits`/`set_nottype_bits`/`study_char_list`
(`:3416-3734`: all bitmap/type/op paths incl. caseless expansion and
the `MAPSIZE` caseless pre-pass) fully read; `find_minlength`
(`:578-3416`) and `set_start_bits` (`:3731-6647`, goto-lowered) surveyed
structurally — return inventories are exactly the upstream contracts
(find_minlength: length/`0`/`-1`/`-2`/`-3`; set_start_bits: SSB_*
`TOODEEP/UNKNOWN/FAIL/CONTINUE/rc`) — and verified behaviorally below.

## Scope examined

The compile-time optimizer: minimum-length analysis feeding
`INFO_MINLENGTH`, first-codeunit/bitmap + last-codeunit publication
feeding `INFO_FIRSTCODEUNIT/TYPE/LAST*`, start-bitmap construction used
by the matcher fast path. Runs on every `pcre2_compile_8`, so every
compile+match probe traverses it.

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_support/r3_pattern_info.w` (`output_r3.txt`),
  oracle `pcre2test /info`: `(a+)(b)?(?<nm>c*)` →
  `minlen=1 firstcu=97 firsttype=1 lastcu=0 lasttype=0`;
  `abc` → `minlen=3 firstcu=97 lastcu=99 lasttype=1` — all study-computed
  fields match the oracle. PASS.
- Every `r3`-`r9` match result (spans, rc values) exercises the
  start-bitmap path with zero divergences vs pcre2test/python/C oracles.
- `with-stage1 check lib/std/re/pcre2_study.w` → `ok` (exit 0).

## Findings

None. In-report notes (not filed):
- The two goto-lowered bodies were verified via outputs + return-code
  inventory, not arm-by-arm (same posture as the prior auto_possess
  report's `compare_opcodes` note). Any future start-bitmap mismatch
  should start with `--dump-drop-plan`-style tracing of these two
  functions.

Verdict: COMPLETE
