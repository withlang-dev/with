# Primary verification — `lib/std/re/pcre2_chkdint.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-re-support (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 59 lines (single complete read).

## Scope examined

Single function `_pcre2_ckd_smul_8` (`:32-59`): faithful lowering of
PCRE2's checked `int × int → ulong` multiply — widening multiply in
`c_longlong`, overflow report only `if sizeof[c_longlong]() >
sizeof[c_ulong]()`. On LP64 both are 8 bytes so the guard is dead and the
function always stores the (always-fitting) product and returns 0 —
identical to the C original on this platform. Callers: size computations
in compile/match paths.

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_support/r1_misc.w` (`output_r1.txt`):
  `ckd1 rc=0 r=6000000000` (2000000000×3),
  `ckd2 rc=0 r=4611686014132420609` (2147483647², hand-verified),
  `ckd3 rc=0 r=0` (0×12345),
  `ckd4 rc=0 r=18446744073709551581` (-5×7 wrapped to u64 = 2⁶⁴-35,
  matching C's `(unsigned long)(long long)-35`). All `rc=0` as the dead
  guard requires. PASS.
- `with-stage1 check lib/std/re/pcre2_chkdint.w` → `ok` (exit 0).

## Findings

None. In-report notes (not filed):
- Overflow can never be reported on LP64 (guard dead by construction) —
  same as C; callers must not rely on `rc=1` here.

Verdict: COMPLETE
