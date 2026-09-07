# Primary verification — `lib/std/crypto/gcm.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 249 lines (single complete read)

## Scope examined

AES-128-GCM (CTR encrypt + GHASH): `ghash_mult` (`:18`), `ghash_update`
(`:45`), `increment_counter` (`:54`), `AesGcm.new` (`:63`),
`aesgcm_aad`/`AesGcm.aad` (`:86`/`:108`),
`aesgcm_encrypt`/`AesGcm.encrypt` (`:111`/`:147`),
`aesgcm_decrypt`/`AesGcm.decrypt` (`:151`/`:192`),
`aesgcm_tag`/`AesGcm.tag` (`:195`/`:222`), `pub fn aes128_gcm_kat`
(`:230`, NIST SP 800-38D case 2). Deps: `std.crypto.aes`,
`std.crypto.endian`. Callers: `lib/std/tls.w:242,305` (12-byte nonces
only). No gcm test files.

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/gcm/vector.w` (vendored aes+endian+gcm, no name
  collisions): random 16-B key, 12-B IV, 20-B AAD, 48-B PT vector
  from node:crypto (OpenSSL-backed). Decrypt(node-CT)==node-PT,
  encrypt(node-PT)==node-CT, tag==node-tag — all three byte-exact
  (112/112 values). PASS.
- `aes128_gcm_kat()` (pub, called directly): returns 0. Embedded
  ct/tag cross-checked byte-exact against the node oracle
  (ct `0388dace…`, tag `ab6e47d4…` — NIST F.5.2 case 2). PASS.
- `with check lib/std/crypto/gcm.w` → ok (stage1).

## Findings

None. In-report notes (not filed):
- `AesGcm.new` only initializes J0 for `iv_len == 12`; other lengths
  leave J0 zeroed silently (GCM spec defines GHASH-based J0 for
  non-12 IVs). Unreachable today: sole caller tls.w passes 12, and
  the whole surface except the KAT is module-private. Revisit if the
  API is ever made pub (then reject non-12 loudly).
- T13: stack-only state, no heap/Drop; raw borrows caller-owned.

Verdict: COMPLETE
