# Primary verification — `lib/std/encoding/base16.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 47 lines (single complete read)

## Scope examined

RFC 4648 Base16: `base16_value` (`:10`, case-insensitive digit value),
`pub fn base16_encode` (`:20`, canonical uppercase), `pub fn
base16_decode` (`:31`, even-length + full-alphabet pre-validation, then
pairwise decode). Deps: `std.collections`, `std.result`, `std.string`,
`std.encoding` (shared `DecodeError`, already audited, no behavior).
Callers: none in `src/`, `lib/`, `rt/`, `tools/`, `build*` — only the
three committed suites
`test/behavior/behav_std_encoding_rfc4648_{vectors,properties,strict}.w`.
No base16-only test files; coverage is via the shared suites.

## Behavioral matrix (all EXECUTED, oracles independent)

Oracle: `python3 binascii.hexlify/unhexlify` (never self-derived).

- `docs/audit/probes/encoding_base16/probe.w` via
  `out/bootstrap/bin/with-stage1 run` (compiles the real primary file):
  RFC 4648 §8 vectors `""→""`, `"f"→66`, `"fo"→666F`,
  `"foo"→666F6F`, `"foob"→666F6F62`, `"fooba"→666F6F6261`,
  `"foobar"→666F6F626172` — all 7 byte-exact vs oracle. PASS.
- Lowercase decode canonicalizes: `666f6f→666F6F`, `ff→FF`
  (oracle `unhexlify('666f6f')==b'foo'`). PASS.
- All-256-octet round trip (`roundtrip-256-ok`; oracle confirms
  `hexlify` round-trips all 256). PASS.
- Invalid: `"0"`→`InvalidLength`, `"GG"`/`"ZZ"`/`"=="`→`InvalidByte`
  (oracle `unhexlify('ZZ')` raises `Error: Non-hexadecimal digit
  found`). PASS.
- Committed suites `behav_std_encoding_rfc4648_{vectors,properties,
  strict}.w` all print `ok` (stage1 run). PASS.

## Findings

None. In-report notes (not filed):

- Length is checked before alphabet (`"G"` len 1 → `InvalidLength`,
  not `InvalidByte`). Refutation attempt: suspected misclassification;
  the committed strict suite pins exactly this (`expect_invalid_length(
  base16_decode("G"), 1)`), and `DecodeError` carries no severity —
  both variants reject loudly. Behavior is specified-by-test. Not a defect.
- `"=="` → `InvalidByte(0)`, not a padding variant. Refutation
  attempt: suspected a missing `InvalidPadding` case; Base16 has no
  padding in RFC 4648 §8 and the pre-validation loop rejects every
  non-alphabet byte including `=` at the exact offset, which the probe
  executed. Correct as-is.

Verdict: COMPLETE
