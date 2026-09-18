# Primary verification — `lib/std/crypto/hmac.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 74 lines (single complete read)

## Scope examined

HMAC-SHA256 (RFC 2104, BearSSL hmac.c port): `HmacSha256.new`
(`:12`, key>64 hashed, ipad/opad xor), `hmac_update` (`:35`),
`hmac_finish` (`:42`, outer SHA-256 over key++inner-digest),
`hmac_sha256` (`:62`), `hmac_sha256_str` (`:68`, via str_abi
copy/free). Callers: `lib/std/tls.w:8,137,155,166` (TLS PRF). No
hmac test files. All symbols module-private (consistent with
aes/rsa; tls.w reaches them intra-package).

## Behavioral matrix (all EXECUTED)

- `docs/audit/probes/hmac/vectors.w` (vendored str_abi+endian+sha256+
  hmac, no collisions): 5 vectors vs python `hmac`/`hashlib`
  oracle — RFC 4231 #1 (0x0b×20/"Hi There"), RFC 4231 #2
  ("Jefe"), 80-byte long key (key-hash path), empty data, empty
  key. 5/5 PASS, 160/160 bytes.
- Probe-authoring note: `&arr[0]` on a `[u8; 0]` array panics
  (`index out of bounds`, fail-closed); len-1 arrays with len 0
  work and sha256("") verifies (`e3b0c44…`). Checked `&` indexing
  is the defensible semantic (`&raw` is the unchecked spelling).
- `with check` on hmac.w → ok (compiles; cf. poly1305).

## Findings

None. T13: stack-only ctx, no heap/Drop; key material zeroized
only by scope exit (same as BearSSL port, no explicit wipe —
noted, not filed).

Verdict: COMPLETE
