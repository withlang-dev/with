# Primary verification — `lib/std/re/pcre2_script_run.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-re-support (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 198 lines (single complete read).

## Scope examined

`_pcre2_script_run_8` (`:32-198`): `(*script_run:...)`/`(*atomic_…)`
same-script assertion — first-character script lookup (with
Common/Inherited/Zzzz skip-forward over combining marks), per-character
script agreement with the `ucp_script` table, the Han/Hiragana/Katakana
shared-script set (scripts 30/34/35 mutual acceptance), early `true`
past end.

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_support/r8_xclass_uni.w` (`output_r8.txt`),
  oracle `pcre2test '/(*script_run:\w+)/'`:
  `sr-same rc=1 span=0..3` on `abc def` (== oracle `0: abc`);
  `sr-mixed rc=1 span=0..3` on `abc α` — stops at the Latin→Greek
  script change (== oracle's `abc αβγ → 0: abc`). PASS.
- `with-stage1 check lib/std/re/pcre2_script_run.w` → `ok` (exit 0).

## Findings

None.

Verdict: COMPLETE
