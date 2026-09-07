# Audit: lib/std/crypto/aes.w @ 450733e5 — COMPLETE

Module: AES-128 encrypt-only block cipher (FIPS-197), sole in-repo consumer
`lib/std/crypto/gcm.w`. No defects found. All candidate findings refuted
against in-repo callers and landed-commit intent.

## Oracles (independent, never self-derived)
- O1 `openssl enc -aes-128-ecb -K … -nopad`: FIPS-197 App.B vector
  key 2b7e151628aed2a6abf7158809cf4f3c, pt 3243f6a8885a308d313198a2e0370734
  → 3925841d02dc09fbdc118597196a0b32 (matches comment at aes.w:91 and
  tests/test_crypto.w:91).
- O2 `openssl` all-zero key/pt → 66e94bd4ef8a2c3b884cfa59ca342b2e (negative control).
- O3 Python GF(2^8)/0x11b synthesis of AES S-box + Rcon from FIPS-197 §5.1.1:
  all 256 S-box entries match aes.w:9-42 exactly; Rcon[0..10] matches aes.w:46-47.

## Probes
- P1 `docs/audit/probes/aes/main.w` (FIPS-197 + zero-vector encrypt compare): HELD.
  No available toolchain can execute repo-HEAD AES: `with run` binds
  `<embedded-std>` (installed v0.15.1.6 and out/bootstrap/bin/with-stage1 agree),
  where non-`pub` `Aes128` is correctly rejected for user-tier code
  ("private to module", per Sema.w `decl_visible_from_current` std-internal
  boundary rule); repo-HEAD `with check` has no `run --lib` override.
  Refutation that this is environmental, not a module defect:
  `with check lib/std/crypto/gcm.w` → ok (sibling-std use of `Aes128` legal).
- P2 Committed suite `tests/test_crypto.w::test_aes128` (file exists): HELD.
  File is stale at HEAD independent of this module — `-> void` externs
  (test_crypto.w:12 etc.) rejected by every available toolchain (HEAD wants
  `-> Unit`, cf. lib/std/box.w:6); fails identically for all crypto tests.
  Pre-existing, outside aes.w scope; see Obs-1.

## Traces
- T13 ownership/drop: clean. No heap, no Drop needed (fixed `[u8; 176]` only).
  `Aes128.new` (aes.w:74-77) returns owned value; sole caller moves it once
  into `AesGcm.aes` (gcm.w:64,80-81), borrowing `&aes_ctx as *const` only
  before the move (gcm.w:67). `aes128_encrypt_block` copies round keys to a
  176-byte stack buffer (aes.w:126-129) — wasteful but sound (no aliasing).
- T15 migration fidelity: no `pub` ever present (`git log -S pub`: 0 hits);
  non-pub surface predates migration (since dd11031e) — intent, not regression.
  Round structure, RotWord/SubWord/Rcon key schedule, ShiftRows (incl. row-3
  right-rotate, aes.w:100-104), MixColumns `a^r^xtime` form (aes.w:114-117),
  and `xtime` (aes.w:50-53) all verified line-by-line against FIPS-197.
- T22 spec conformance: encrypt path is structurally exact
  (AddKey; 9× Sub/Shift/Mix/AddKey r=1..9; final Sub/Shift/AddKey(160)).
  Index safety: `aes_sbox(u8 as i32)` ∈ 0..255; `aes_rcon(i-1)`, i∈1..11 →
  0..9, in range. Encrypt-only (no decrypt) matches GCM's needs — not a defect.

## Findings
None. (Numbered-candidate refutations: C1 external-use privacy error —
refuted: std-internal boundary rule, gcm.w checks ok, never-pub history;
C2 stale `void` test file — refuted as aes.w defect: pre-existing, affects all
tests equally, owned by tests/test_crypto.w.)

## Observations (non-defect)
- Obs-1: tests/test_crypto.w cannot compile at HEAD (`void` vs `Unit`) and
  directly names std-internal `Aes128`; claimed AES-128 test coverage is
  currently non-executable. Recommend fixing the test file, not this module.
- Obs-2: `Aes128`/`AesGcm` expose no `pub` API (only gcm.w:230
  `pub fn aes128_gcm_kat`); AES-128 is unavailable to user programs by
  longstanding design. No change recommended without a std-API decision.

Verdict: COMPLETE — no defects, S-box/Rcon proven vs O3, vectors vs O1/O2, probes P1/P2 HELD (reasons above).
