# Primary verification — `lib/std/re/pcre2_extuni.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-re-support (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 164 lines (single complete read).

## Scope examined

`_pcre2_extuni_8` (`:32-164`): `\X` grapheme-cluster advance — CR/LF pair
skip, control/extend/ZWJ/RI/spacingmark/prepend property walk via
`ucp_gentype`, GB11 (extended-pictographic × Extend × ZWJ × EP) sequence
handling. Consumed by the matcher's `\X` opcode (OP_EXTUNI).

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_support/r8_xclass_uni.w` (`output_r8.txt`):
  `\X` (UTF+UCP) on NFD `e`+U+0301 (3 bytes, 2 codepoints) →
  `x-nfd rc=1 span=0..3` (one cluster — grapheme glue works);
  on NFC U+00E9 (2 bytes) → `x-nfc rc=1 span=0..2`.
  Oracle: `pcre2test '/\X/utf' on é → 0: \x{e9}` (same single-cluster
  semantics). PASS.
- `with-stage1 check lib/std/re/pcre2_extuni.w` → `ok` (exit 0).

## Findings

None.

Verdict: COMPLETE
