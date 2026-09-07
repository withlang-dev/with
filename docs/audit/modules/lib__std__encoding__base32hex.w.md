# Primary verification — `lib/std/encoding/base32hex.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 107 lines (single complete read)

## Scope examined

RFC 4648 Base32 extended hex: `base32hex_value` (`:10`, 0–9/A–V
case-insensitive), `base32hex_encoded_len` (`:19`),
`base32hex_validate` (`:24`), `pub fn base32hex_encode` (`:53`),
`pub fn base32hex_decode` (`:85`). Line-for-line structural twin of
`base32.w` with only the alphabet (`0123456789ABCDEFGHIJKLMNOPQRSTUV`)
and value function differing. Deps/callers: same as base32 (no
`src/`/`lib/`/`rt/`/`tools/` callers; only the three committed
`behav_std_encoding_rfc4648_*.w` suites).

## Behavioral matrix (all EXECUTED, oracles independent)

Oracle: `python3 base64.b32encode` translated through
`str.maketrans('ABCDEFGHIJKLMNOPQRSTUVWXYZ234567',
'0123456789ABCDEFGHIJKLMNOPQRSTUV')` (never self-derived).

- `docs/audit/probes/encoding_base32hex/probe.w` via
  `out/bootstrap/bin/with-stage1 run`: RFC 4648 §7 vectors `""→""`,
  `"f"→CO======`, `"fo"→CPNG====`, `"foo"→CPNMU===`,
  `"foob"→CPNMUOG=`, `"fooba"→CPNMUOJ1`,
  `"foobar"→CPNMUOJ1E8======` — all 7 byte-exact vs oracle. PASS.
- Lowercase decode: `cpnmu===→CPNMU===`. PASS.
- Invalid: `"CO"`→`InvalidLength`, `"CW======"`→`InvalidByte`
  (`W` is outside 0–9/A–V), `"0======="`, `"00====0="`→
  `InvalidPadding`, `"CP======"`, `"CPNMV==="`→`NonCanonicalBits`. PASS.
- Committed suites vectors/properties/strict all print `ok`
  (properties suite additionally pins base32hex sort-ordering over
  all 65536 two-octet inputs). PASS.
- Twin-divergence check: `diff` of control flow vs `base32.w` shows
  only alphabet/value-function differences; bit-split constants
  (`v0..v7`, symbol counts, masks, `removed` map) identical. PASS
  (held comparison, executed behavior above).

## Findings

None. In-report notes (not filed):

- Same mask/remaining-set reasoning as base32 applies unchanged
  (identical integers, verified by the twin diff); probe executed
  pad6 (`CP======`) and pad3-adjacent (`CPNMV===`) rejections, strict
  suite covers the rest (`CPNH====`, `CPNMUOH=`). Not a defect.
- `W–Z` rejected while `w–z` likewise rejected: value fn caps
  uppercase at 86 (`V`) and lowercase at 118 (`v`). Refutation
  attempt: suspected asymmetric case handling; both ranges end at
  the 32nd symbol (`V`/`v` = value 31), and the probe's
  `"CW======"`→`InvalidByte` plus strict-suite `"0?======"`
  executed the boundary. Correct.

Verdict: COMPLETE
