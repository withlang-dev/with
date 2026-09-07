# Primary verification — `lib/std/encoding/base32.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 107 lines (single complete read)

## Scope examined

RFC 4648 Base32: `base32_value` (`:10`, A–Z case-insensitive, 2–7),
`base32_encoded_len` (`:19`), `base32_validate` (`:24`, `%8` length,
trailing-pad position set {1,3,4,6}, pad-after-data ordering,
trailing-bits canonical mask), `pub fn base32_encode` (`:53`,
canonical uppercase padded), `pub fn base32_decode` (`:85`,
validate-then-decode, final-quantum symbol count). Deps: same shared
surface as base16 (`std.encoding` audited). Callers: none in `src/`,
`lib/`, `rt/`, `tools/`, `build*` — only the three committed
`behav_std_encoding_rfc4648_*.w` suites.

## Behavioral matrix (all EXECUTED, oracles independent)

Oracle: `python3 base64.b32encode / b32decode(casefold=True)`
(never self-derived).

- `docs/audit/probes/encoding_base32/probe.w` via
  `out/bootstrap/bin/with-stage1 run`: RFC 4648 §6 vectors `""→""`,
  `"f"→MY======`, `"fo"→MZXQ====`, `"foo"→MZXW6===`,
  `"foob"→MZXW6YQ=`, `"fooba"→MZXW6YTB`,
  `"foobar"→MZXW6YTBOI======` — all 7 byte-exact vs oracle. PASS.
- Lowercase decode: `mzxw6===→MZXW6===`,
  `mzxw6ytboi======→MZXW6YTBOI======`
  (oracle `b32decode('mzxw6===',casefold=True)==b'foo'`). PASS.
- Invalid: `"MY"`→`InvalidLength`, `"M0======"`→`InvalidByte`,
  `"A======="`, `"AA====A="`→`InvalidPadding`,
  `"MZ======"`, `"MZXW7==="`→`NonCanonicalBits`. PASS.
- Committed suites vectors/properties/strict all print `ok`
  (properties suite covers 0–257 + 65536 lengths, all single octets,
  boundary round trips). PASS.

## Findings

None. In-report notes (not filed):

- Trailing-bit masks (pad6→3, pad4→15, pad3→1, pad1→7) re-derived
  from bit arithmetic: 2 symbols = 10 bits → 1 byte + 2 unused (mask
  `0b11`); 4 symbols = 20 bits → 2 bytes + 4 unused (mask `0b1111`);
  5 symbols = 25 bits → 3 bytes + 1 unused; 7 symbols = 35 bits → 4
  bytes + 3 unused. All four match the code; probes executed the
  pad6/pad4 and pad3/pad1-adjacent rejections (`MZ======`,
  `MZXR====`, `MZXW7===`, `MZXW6YR=` in the strict suite). Not a defect.
- `remaining != 1 and != 3 and != 4 and != 6` counts first-pad to
  end-of-text. Refutation attempt: suspected multi-quantum confusion
  (e.g. `"MY======MZXW6YTB"` remaining 14 → correctly
  `InvalidPadding`; `"MZXW6YTBMY======"` remaining 6 with a clean
  first quantum → correctly accepted as 5+1 bytes). Legal pad-count
  set is exhaustive per quantum, and any pad before the final quantum
  trips either the remaining check or the pad-ordering check. Not a defect.
- `NonCanonicalBits` is only checked when padding > 0, at
  `first_pad - 1`. Refutation attempt: looked for an unpadded
  non-canonical path; a full 8-symbol quantum has zero unused bits by
  construction (40 bits = 5 bytes), so there is nothing to check.
  Complete.

Verdict: COMPLETE
