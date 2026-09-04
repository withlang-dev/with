# Primary verification — `lib/std/re/pcre2_serialize.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-re-support (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 356 lines (single complete read).

## Scope examined

`pcre2_serialize_encode_8` (`:32-`: null codes→-51, per-code
`blocksize` walk, `SERIALIZE_ENCODED_SIZE` magic + `PCRE2_SIZE` header,
`with_alloc` + `memcpy` flatten), `pcre2_serialize_decode_8`
(`:129-`: magic check → -31 BADSERIALIZED, count bounds, fresh
`with_alloc` + copy per slot), `pcre2_serialize_get_number_of_codes_8`
(`:242-`: magic-gated count, -1 on garbage), `pcre2_serialize_free_8`
(`:301-`: null-safe).

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_support/r6_convert_serialize.w`
  (`output_r6.txt`), pattern `(a+)(b)?`:
  `enc rc=1 size=1283 ncodes=1`, `dec rc=1`,
  `rt-match rc=3` on `aaab` through the deserialized code (round-trip
  preserves match semantics),
  `dec-badmagic rc=-31 enc-null rc=-51`. PASS.
- `with-stage1 check lib/std/re/pcre2_serialize.w` → `ok` (exit 0).

## Findings

None.

Verdict: COMPLETE
