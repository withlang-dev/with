# Primary verification — `lib/std/re/pcre2_valid_utf.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-re-support (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 259 lines (single complete read).

## Scope examined

`_pcre2_valid_utf_8` (`:32-259`): DFA-free table-driven validator —
`utf8_table4` lead-byte extra-byte counts; trailing-byte top-bits check
(-8..-10 by position); overlong rejections -17/-18/-19 (2/3/4-byte);
surrogate halves -16; >U+10FFFF -15; 5-byte -13, 6-byte -14, FE/FF -23,
lone trail -22; truncation ladder -3..-7 (bytes-missing = ab-length, so
ERR1..ERR5); erroroffset points at the offending lead (0 for the single-
sequence probes, 1 for the mid-string trail). Matches PCRE2's documented
UTF8_ERRn numbering (defs `PCRE2_UTF8_ERR1..21 = -3..-23`).

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_support/r2_valid_utf.w` (`output_r2.txt`), oracle
  python3 strict decode (valid/invalid + position agree on all 17):
  `ascii/e-acute/euro/grin rc=0`,
  `lone-trail rc=-22 off=1`,
  `trunc-e2 rc=-4 off=0`, `trunc-e282 rc=-3 off=0`,
  `trunc-f09f rc=-4 off=0`,
  `overlong2 rc=-17`, `overlong3 rc=-18`, `overlong4 rc=-19`,
  `bad-cont rc=-8`, `surrogate rc=-16`, `beyond-10ffff rc=-15`,
  `fe rc=-23`, `five-byte rc=-13`, `six-byte rc=-14` (all `off=0`).
  Every code equals the PCRE2-documented meaning for the vector. PASS.
- `with-stage1 check lib/std/re/pcre2_valid_utf.w` → `ok` (exit 0).

## Findings

None.

Verdict: COMPLETE
