# Audit: lib/std/crypto/ec.w @ 450733e5 — VERDICT: INCOMPLETE

Scope: full-module read-only audit of NIST P-256 (Jacobian + i31 Montgomery) at
commit 450733e5. Oracles are INDEPENDENT only: system `openssl ec -text` /
`openssl pkeyutl -derive` (OpenSSL 3.6.3) and python3 integer arithmetic for
FIPS 186-4 / SEC2 constants. No self-derived vectors used.

## Oracle-verified results (all EXECUTED, all pass)

- Constants exact: `p` bytes (ec.w:15-20) == 2^256-2^224+2^192+2^96-1;
  `n` bytes (ec.w:25-30) == SEC2 order; `b` bytes (ec.w:35-40) == SEC2 b
  (byte-compared in python); `Gx/Gy` (ec.w:45-60) == openssl `priv=1 -> pub`.
- G on curve (python): `(y² - (x³-3x+b)) mod p == 0` → True.
- `p-2` trailer byte 0xFD (ec.w:104) matches python `hex((p-2)%256)`.
- Vendored probe `docs/audit/probes/ec/vendored_probe.w` (= bigint.w 284 lines +
  ec.w minus its `use` line + assert main; mechanical concat only) run with
  `out/bootstrap/bin/with-stage1 run` → `ec-probe-pass`. It asserts:
  priv=1 → G, priv=2 → 2G `(7cf27b18…/07…d1)` vs openssl oracle,
  RFC 6979 A.2.5 d → Q vs openssl oracle (full X/Y spot bytes
  `60..b6` / `79..99`, superset of test_ec.w's partial asserts — every byte
  test_ec.w asserts matches the openssl oracle),
  ECDH symmetry 3·pub(5)==5·pub(3) 32/32 bytes, and
  ECDH secret == `openssl pkeyutl -derive` (`f0454dc6…9b9d5f`) 32/32 bytes.
- Negative control: same probe with one expected byte flipped
  (`0x7c`→`0x7d`) fails at the exact assert line. Probes are live.
- T22 formulas: `point_double` (ec.w:191-236) is Guide-to-ECC Alg 3.21 for
  a=-3 (M=3(X²-Z⁴), S=4XY², X3=M²-2S, Z3=2YZ, Y3=M(S-X3)-8Y⁴ — the triple
  doubling at ec.w:233-235 is ×8); `point_add` (ec.w:240-320) is Alg 3.22
  (U/S/H/R/H²/H³/V/U1H²/Z1Z2H all in the right places). Doubling (0,0,0)
  is a fixed point, so MSB-first `point_mul` from identity (ec.w:324-349)
  is sound; H==0/R==0 → double, H==0/R!=0 → zero (ec.w:289-295) correct.
- T13 ownership: all buffers stack `[u32; N]` value arrays; `&raw mut`
  borrows never overlap a live `*const` use — the three aliasing hazards
  are already split into `z2_cubed/z1_cubed` (ec.w:279-284), `u1h2`
  (ec.w:305-306), `z1z2` (ec.w:318-320), matching landed intent
  (4dd0ae02, bc0956c5); callers (`ecdsa.w:114-116`, `tls.w:675-679`) pass
  disjoint buffers. No heap, no drop/leak surface.
- T15: module body is migrated (`&raw mut`, `as *const`, `unsafe fn` +
  `unsafe {}` call sites); it compiles under the current stage1 (vendored
  probe built clean).

## Findings

1. (high, target tests/test_ec.w:39,5) Claimed EC coverage does not execute.
   `with-stage1 check/run` fails: `unsafe:` single-line syntax (rejected,
   needs `unsafe {}`), `&mut` (line 39), `-> void` (line 5), missing
   `use std.builtins.int_to_string`. File exists (verified) but is stale
   since the p5.4 migration (309ed3c5). Same staleness in tests/test_ecdsa.w
   (lines 5-6,56,65,75,85), tests/test_bigint.w, tests/test_crypto.w.
   Probe status EXECUTED (oracle: stage1 itself). Refutation attempt: no
   other runnable in-repo EC vector suite found; the RFC 6979 bytes the
   stale test asserts were confirmed correct against openssl, so only the
   harness — not the vectors — is broken.
2. (medium, target lib/std/crypto/ec.w:403,440) `p256_compute_public` /
   `p256_ecdh` are module-private (no `pub`; external probe call denied:
   `symbol 'p256_compute_public' is private`), despite the `── Public API ──`
   header. Intra-std callers (tls.w, ecdsa.w) are unaffected. External users
   have no reachable P-256 API. Probe status EXECUTED (privacy error
   observed). Refutation: whether lib builds intra-package was not
   re-verified here (inferred from callers, not observed) — recorded, not
   claimed.
3. (medium, target lib/std/crypto/ec.w:440-470) `p256_ecdh` does no peer-key
   validation (no 0x04 prefix check, no on-curve check, no infinity check);
   `tls.w:679` feeds network bytes straight in. k=0/invalid input yields an
   implementation-defined secret via `fe_inv(0)`. Probe status HELD (no
   independent oracle defines the degenerate output; asserting it would
   enshrine behavior). Refutation: ecdsa.w checks r/s range + identity
   result, but the ECDH path has no equivalent — survives refutation.
4. (info, target lib/std/crypto/ec.w:324-349) `point_mul` double-and-add is
   input-dependent variable-time; fine for verify, notable for ECDHE
   signing/decryption-adjacent use in tls.w. Probe status HELD (no timing
   harness in scope).

## Probes run

- `docs/audit/probes/ec/vendored_probe.w` (via keygen/ecdh snippet + vendored
  body) — EXECUTED, `ec-probe-pass`, oracles: openssl + python/FIPS.
- `/tmp/tamper_probe.w` (single-byte flip) — EXECUTED, fails as required.
- k=0/infinity degenerate probe — HELD (reason above).

Verdict: INCOMPLETE — the P-256 math verifies exactly against independent
oracles, but in-repo executable coverage is stale (finding 1), so the module
is correct-by-audit, not correct-by-CI.

Close-out (primary, 2026-09-04): test_ec/test_ecdsa staleness
re-executed (unsafe: rejected at test_ec.w:39, test_ecdsa.w:56).
Filed #1055 ([crypto] ec/ecdsa suites stale + P-256 public-API header
vs private visibility). NOT filed by judgment: finding 3 (no peer-key
validation — held without an oracle defining degenerate output; owner
decision) and finding 4 (variable-time point_mul info).
