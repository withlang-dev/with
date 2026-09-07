# Primary verification — `lib/std/crypto/ecdsa.w`

Status: **COMPLETE**
Primary verifier: workflow child (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 145 lines (single complete read)

## Scope examined

`ecdsa_p256_verify` (`:14-18`, `unsafe fn`, private to module): P-256 ECDSA
verification — load order/prime (`:20-27`), decode + range-check r/s
(`:29-37`), Fermat inverse `w = s^(n-2)` (`:39-50`), `u1 = z*w`,
`u2 = r*w` via Montgomery multiply (`:52-72`), byte-encode scalars
(`:74-78`), generator `G` and pubkey `Q` in Jacobian Montgomery form
(`:80-108`), `R = u1*G + u2*Q` (`:110-116`), infinity rejection
(`:118-120`), affine-x `mod n` compare vs `r` (`:122-145`).

Task-label mapping (per overview definitions, cf. sibling `box` report):
T13 = MIR/codegen + ownership/drop agreement, T15 = allocator/container
ownership and migration fidelity, T22 = specification coverage. Traced:
caller-owned raw-pointer buffers with fixed-size stack arrays (T13/T15),
BearSSL `ecdsa_i31_vrfy_raw.c` fidelity (T15), FIPS 186-4 `§4.7` / RFC 6979
conformance (T22).

## Behavioral matrix

Probe `docs/audit/probes/ecdsa_verify/matrix.w` (RFC 6979 A.2.5 vector +
edges; `run` requires intra-package visibility, so executed via temp copy
at `lib/std/crypto/audit_probe_ecdsa_tmp.w`, removed after; `git status`
clean of probe residue). Seed `out/bootstrap/bin/with-stage1` at
450733e5, `run` rc=0, stdout exactly:

```text
1
0
0
0
0
0
0
```

i.e. valid→1; r=0→0; s=0→0; r=n→0; s=n→0; corrupted-r→0; pubkey
(0,0)→0 with no crash. All EXECUTED.

Independent oracles (never self-derived):

- python-`hashlib`: `SHA256("sample")` = `af2bdbe1…add1bf`, byte-equal to
  `tests/test_ecdsa.w:36-41` digest (EXECUTED).
- `openssl 3.6.3 dgst -sha256 -verify` on SPKI rebuilt from the test
  pubkey + DER re-encoded (r,s) over message `sample`: `Verified OK`
  (EXECUTED). Negative controls EXECUTED: bit-flipped sig →
  `Verification failure`; `sample!` message → `Verification failure`.
- python big-int: `n-2` recomputed from P-256 order equals the hardcoded
  `nm2` bytes at `:41-46` (`…FC63254F`) (EXECUTED).
- BearSSL upstream `ecdsa_i31_vrfy_raw.c` (freebsd-src mirror, fetched)
  used as migration-fidelity oracle for Finding 1 (READ).

Callee-contract check (READ): 12-u32 field limbs, 36-u32 Jacobian points,
32-byte scalars match `ec.w` (`POINT_WORDS 36` at `ec.w:152`,
`point_mul` at `ec.w:324`, `point_to_affine` at `ec.w:353`);
`i31_decode_reduce` at `bigint.w:71` reduces mod m per byte
(`i31_reduce_once`, `bigint.w:90`), confirming the Finding 1 mechanism.

In-repo coverage (files verified to exist): `tests/test_ecdsa.w` exists
(89 lines, RFC 6979 A.2.5 + corrupt-r + corrupt-hash cases) but does NOT
build at this commit — see Finding 2. No `test/behavior/` coverage for
ECDSA (name search negative). Sole in-repo caller `x509.w:479`
(`ecdsa_verify_der_sig`, READ `:418-485`) passes DER-parsed 32-byte
r/s and uncompressed-point halves straight through.

## Findings

1. [LOW, T15/T22] Missing explicit `r,s < n` rejection —
   `lib/std/crypto/ecdsa.w:30-33`. Inputs are folded with
   `i31_decode_reduce` (mod-n reduction) and only zero-checked, while
   BearSSL `ecdsa_i31_vrfy_raw.c` uses `br_i31_decode_mod`, which
   REJECTS `r,s >= n`, and FIPS 186-4 `§4.7` step 1 requires
   `1 <= r,s <= n-1`. A 32-byte `r` in `[n, 2^256)` is silently reduced
   instead of rejected. Probe status: EXECUTED for `r = n` / `s = n`
   (both → 0, consistent with both implementations since they reduce to
   zero); distinguishing accept-case HELD — exhibiting divergence needs
   `R.x ≡ r-n`, i.e. a signing oracle for the reduced value, beyond the
   available toolchain. Refutation attempt: no forgery impact — reduction
   maps the attacker into `[0, n)` and the ECDSA equation must still hold
   on the reduced value, so out-of-range inputs grant no advantage over
   in-range ones; direction is fail-closed in every constructible case.
   Kept as LOW conformance/fidelity nit, not a vulnerability.

2. [INFO, T22] Committed test does not build at this commit —
   `tests/test_ecdsa.w:5-6` (`-> void`, rejected: "With uses Unit"),
   `:56,65,75` (inline `let ok = unsafe: …`, rejected: "unsafe: requires
   a newline and indented block"). `with-stage1 test tests/test_ecdsa.w`
   → `error: test build failed`, EXECUTED (error quoted verbatim from
   run). The `void` drift independently EXECUTED via
   `tests/test_crypto.w:12`. Refutation vs landed intent `ea9f2c5e`
   ("passes RFC 6979 A.2.5 … All suites pass"): true under the older
   frontend at landing; rot comes from later frontend changes, not from
   `ecdsa.w` logic — the module itself is exonerated by the matrix probe
   and openssl oracle above. Effect at 450733e5: zero committed
   executable coverage for this module (whole `tests/` dir is similarly
   stale). No change to `ecdsa.w` warranted.

3. [INFO, T22] No on-curve validation of `Q` — `lib/std/crypto/ecdsa.w:99-100`
   decodes arbitrary `(x, y)` with `Z = 1` and proceeds; caller `x509.w`
   only checks length/`0x04` prefix (`x509.w:476`). Matches BearSSL
   `raw` verify (no curve-membership check either — fidelity HELD by
   construction). Probe status: EXECUTED — pubkey `(0,0)` with valid
   `(r,s,hash)` → 0, no crash/hang. Refutation: invalid points produce
   arithmetic garbage that fails the final `v == r` compare (safe
   direction); X.509 path inherits the same property. Accepted risk,
   noted for the record.

## Negative controls (all EXECUTED)

- Module probe: r=0, s=0, r=n, s=n, bit-flipped r, (0,0) pubkey all → 0;
  valid vector → 1 (matrix above, oracle: seed stage1).
- OpenSSL oracle: corrupted signature and wrong message both →
  `Verification failure` (oracle: system openssl 3.6.3).
- `w_m` Montgomery-reuse read (`:71` reuses `w_m` after `:63`): READ-only
  check — `i31_montmul` does not mutate inputs (`bigint.w:165`), so `w_m`
  is still valid Montgomery form; the valid→1 probe result confirms the
  scheduling end-to-end.
- `nm2`-as-`n` confusion guard: hardcoded `n-2` independently recomputed
  (oracle: python big-int); `i31_modpow(x, e, elen, …)` arg order matches
  `bigint.w:227` (READ).

## T13 ownership/drop trace

All locals are fixed-size value arrays (`[u32; 12]`, `[u8; 32]`,
`[u32; 36]`) plus two plain ints (`match_val`, `ci`); all inputs are
caller-owned `*const u8`; callees take raw pointers and allocate nothing;
no `Drop` types, no heap, no early-return resource release needed
(`return 0` paths at `:35-37`, `:119-120` return `i32` by value).
Constant-time shape: final compare loops all 32 bytes with no early break
(`:138-143`). No finding.

## Verdict

Verdict: COMPLETE — `lib/std/crypto/ecdsa.w` correctly implements FIPS 186-4 P-256 verification (valid RFC 6979 A.2.5 vector accepted, all edge/negative probes rejected, openssl cross-check agrees); 3 numbered findings (1 LOW conformance nit, 2 INFO, none blocking).
