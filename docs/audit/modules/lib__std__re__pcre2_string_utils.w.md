# Primary verification — `lib/std/re/pcre2_string_utils.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-re-support (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 118 lines (single complete read).

## Scope examined

Six byte-string helpers (`:32-118`): `_pcre2_strlen_8`,
`_pcre2_strcmp_8` (unsigned-compare, first-difference sign), two
`strncmp` variants (early `n==0`→0; second form's
`(n-1)&(n!=0)` guard collapses to the same), `_pcre2_strcpy_c8_8`
(returns length), `_pcre2_strcmp_c8_8` (c8 literal vs buffer).

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_support/r1_misc.w` (`output_r1.txt`):
  `strlen=2 strcmp_hi_hj=-1 strcmp_hi_hi=0 strncmp1=0 strncmp0=0`,
  `strcpy=3 s2=0` — all match libc semantics. PASS.
- `with-stage1 check lib/std/re/pcre2_string_utils.w` → `ok` (exit 0).

## Findings

None.

Verdict: COMPLETE
