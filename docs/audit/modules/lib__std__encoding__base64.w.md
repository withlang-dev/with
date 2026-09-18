# Primary verification — `lib/std/encoding/base64.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 92 lines (single complete read)

## Scope examined

RFC 4648 Base64: `base64_value` (`:10`, strict A–Za–z0–9+/ — case
significant), `base64_encoded_len` (`:23`), `base64_validate` (`:28`,
`%4` length, max 2 pads, pad-ordering, trailing-bits mask),
`pub fn base64_encode` (`:56`, canonical padded),
`pub fn base64_decode` (`:77`). Deps/callers: same shared surface;
no `src/`/`lib/`/`rt/`/`tools/` callers, only the three committed
`behav_std_encoding_rfc4648_*.w` suites.

## Behavioral matrix (all EXECUTED, oracles independent)

Oracle: `python3 base64.b64encode` (never self-derived).

- `docs/audit/probes/encoding_base64/probe.w` via
  `out/bootstrap/bin/with-stage1 run`: RFC 4648 §4 vectors `""→""`,
  `"f"→Zg==`, `"fo"→Zm8=`, `"foo"→Zm9v`, `"foob"→Zm9vYg==`,
  `"fooba"→Zm9vYmE=`, `"foobar"→Zm9vYmFy` — all 7 byte-exact. PASS.
- High-bit vectors: `[20,251,156,3,217,126]→FPucA9l+`,
  `[251,255]→+/8=`, decode-then-encode `+/8=→+/8=` (oracle-exact). PASS.
- Strict alphabet: `"-_8="`→`InvalidByte` (oracle: std b64 rejects
  `-`/`_`). PASS.
- Invalid: `"Zg"`→`InvalidLength`, `"A==="`/`"AA=A"`→`InvalidPadding`,
  `"Zh=="`/`"Zm9="`→`NonCanonicalBits`. PASS.
- Committed suites vectors/properties/strict all print `ok`
  (properties suite: 0–257 + 65536 lengths, all 256 one-octet and all
  65536 two-octet round trips). PASS.

## Findings

None. In-report notes (not filed):

- Trailing-bit masks (pad2→15, pad1→3): 2 symbols = 12 bits → 1
  byte + 4 unused (`0b1111`); 3 symbols = 18 bits → 2 bytes + 2
  unused (`0b11`). Re-derived from arithmetic, match the code; both
  executed by probe (`Zh==` = `h`:33 & 15 = 1 ≠ 0;
  `Zm9=` = `9`:61 & 3 = 1 ≠ 0). Not a defect.
- Case significance: `Zg==` vs `zg==` decode differently (strict
  suite `test_base64_case_is_significant` executed). Refutation
  attempt: suspected the value fn might fold case like base32; the
  ranges map disjointly (A–Z→0–25, a–z→26–51) and the suite pins
  distinct outputs. Correct per RFC 4648 §4 (case-sensitive alphabet).
- `"A==="` (3 pads) rejected via `text.len() - i > 2`. Refutation
  attempt: checked whether a 4-char all-pad quantum or `"=AAA"`
  slips through — both hit `InvalidPadding` (probe + strict suite
  executed `"A==="`, `"=AAA"`, `"AA=A"`, `"AAAA===="`). Exhaustive:
  legal pad counts per quantum are exactly {0,1,2}.

Verdict: COMPLETE
