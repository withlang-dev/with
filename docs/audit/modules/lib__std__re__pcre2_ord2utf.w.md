# Primary verification — `lib/std/re/pcre2_ord2utf.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-re-support (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 86 lines (single complete read).

## Scope examined

`_pcre2_ord2utf_8` (`:32-86`): 1/2/3/4-byte UTF-8 encoder with the
surrogate-rejection (`0xD800-0xDFFF` → `c+0x10000`, matching upstream's
CESU-8-compatible reading) and `>0x10FFFF` → 4-byte fallback write.
Callers: compile-time literal emission, substitute case-forcing,
convert.

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_support/r1_misc.w` (`output_r1.txt`), oracle
  python3 `chr(cp).encode('utf-8')`:
  `ord41 n=1 b=65`,
  `ord7ff n=2 b=223 191` (DF BF),
  `ord20ac n=3 b=226 130 172` (E2 82 AC),
  `ord1f600 n=4 b=240 159 152 128` (F0 9F 98 80) — byte-exact at every
  encoding-length boundary. PASS.
- `with-stage1 check lib/std/re/pcre2_ord2utf.w` → `ok` (exit 0).

## Findings

None.

Verdict: COMPLETE
