# Primary verification — `lib/std/encoding/base64url.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 92 lines (single complete read)

## Scope examined

RFC 4648 Base64URL: `base64url_value` (`:10`, `-`→62, `_`→63),
`base64url_encoded_len` (`:23`), `base64url_validate` (`:28`),
`pub fn base64url_encode` (`:56`, canonical padded),
`pub fn base64url_decode` (`:77`). Line-for-line structural twin of
`base64.w` with only the alphabet
(`...0123456789-_` vs `...+/`) and value function differing.
Deps/callers: same as base64 (no `src/`/`lib/`/`rt/`/`tools/`
callers; only the three committed suites).

## Behavioral matrix (all EXECUTED, oracles independent)

Oracle: `python3 base64.urlsafe_b64encode` (never self-derived).

- `docs/audit/probes/encoding_base64url/probe.w` via
  `out/bootstrap/bin/with-stage1 run`: `""→""`, `"f"→Zg==`,
  `"fo"→Zm8=`, `"foo"→Zm9v`, `"foob"→Zm9vYg==`,
  `"fooba"→Zm9vYmE=`, `"foobar"→Zm9vYmFy` (identical to base64 here,
  as RFC 4648 §5 requires for these inputs), plus
  `[251,255]→-_8=` and decode-then-encode `-_8=→-_8=`
  (oracle-exact, url-distinct from base64's `+/8=`). PASS.
- Strict alphabet separation, both directions executed:
  base64url rejects standard `"+"/"/"` (`"+/8="`→`InvalidByte`),
  and base64 rejects url `"-"/"_"` (`"-_8="`→`InvalidByte`, base64
  probe). No cross-acceptance. PASS.
- Invalid (mirrors base64): `"Zg"`→`InvalidLength`,
  `"A==="`/`"AA=A"`→`InvalidPadding`,
  `"Zh=="`/`"Zm9="`→`NonCanonicalBits`. PASS.
- Committed suites vectors/properties/strict all print `ok`
  (same exhaustive short-input coverage as base64, dual-run). PASS.
- Twin-divergence check vs `base64.w`: only alphabet/value-function
  differences. PASS (held comparison, executed behavior above).

## Findings

None. In-report notes (not filed):

- Padded (not unpadded) URL form: encode always emits `=` and
  validate requires `%4==0`. Refutation attempt: suspected JOSE-style
  unpadded input should be accepted; the module documents "canonical
  padded RFC 4648 Base64URL", the strict suite pins
  `InvalidLength("Zg")`, and silently accepting unpadded input would
  contradict the padding validation the module exists to enforce.
  Behavior is as documented. Not a defect.
- Same mask/pad-count reasoning as base64 (identical integers,
  twin-verified); all four rejection classes executed by probe. Not a defect.

Verdict: COMPLETE
