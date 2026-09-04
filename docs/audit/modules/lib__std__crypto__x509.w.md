# Primary verification — `lib/std/crypto/x509.w`

Status: **Incomplete** (1 High + 1 Medium finding, both filed)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 485 lines (two complete reads)

## Scope examined

DER parser (`der_read_tl` `:28-61`, `der_skip` `:65-72`, `oid_match`
`:75-83`), known OIDs (`:87-140`, all four byte-checked against the
DER comments: 2A 86 48... correct), `X509Cert` offsets struct
(`:155-175`), `x509_parse` (`:190-331`), `identify_sig_alg/key_type`
(`:334-353`), `x509_verify_signature` (`:359-415`),
`ecdsa_verify_der_sig` (`:418-485`).
Callers: sole in-repo caller `lib/std/tls.w:13` (`use`), `tls.w:589-590`
calls `x509_parse` on peer cert bytes — network-input threat model.
No x509-specific test files exist.

## Behavioral matrix (all EXECUTED via vendored probes — symbols private)

- `docs/audit/probes/x509/parse_trunc.w`: openssl-generated 771-byte
  RSA-2048/sha256 cert (independently inspected: Signature Algorithm
  sha256WithRSAEncryption). `x509_parse` returns 1 with key_type=1,
  sig_alg=1, n=149/256, e=407/3, sig=515/256, tbs=4/491 — all
  in-bounds and matching openssl's anatomy. Full-parse path HELD
  correct (oracle: openssl).
- `docs/audit/probes/x509/parse_escape.w`: same cert with buf_len=520
  (inside signatureValue content; TLV header fits) returns **1** with
  sig_start=515, sig_len=256 — range 515..771 escapes the 520-byte
  bound by 251 bytes. Contrast cut buf_len=200 (mid-modulus) returns
  0 (fail-closed). Escape EXECUTED.
- `docs/audit/probes/x509/sig_oversize.w`: DER SEQ{INT(40 arbitrary
  bytes), INT(1)} through vendored `ecdsa_verify_der_sig` (+ stubbed
  `ecdsa_p256_verify`) → `panic: index out of bounds`. EXECUTED.
- `docs/audit/probes/x509/sig_legit33.w` (control): SEQ{INT(0x00 +
  32 bytes), INT(1)} (legit P-256 zero-padded r) → returns stub 0, no
  panic. Boundary exactly r/s_len > 32. EXECUTED.

## Findings

1. `x509_parse` performs no content-length-vs-buffer validation —
   HIGH — filed #1056. `der_read_tl` checks only that the tag+length
   header fits; claimed content lengths are never checked against
   `buf_len`, and `der_skip`/`x509_parse` propagate `cs + cl`
   unchecked. Any *trailing* element whose header fits but whose
   content is truncated yields rc=1 with escaping offsets (proven:
   sig 515+256 vs bound 520). Consumers then perform raw unbounded
   reads over the escaped ranges: `sha256_hash(tbs range)` (`:367`),
   `rsa_pkcs1_sha256_verify` n/e/sig ranges (`:372-377`), `oid_match`
   (`:75-83`, no length check at all), ECDSA r/s/point reads
   (`:479-484`). Peer-cert (tls.w:589) input can thus drive OOB
   reads (CWE-125): crash/DoS at best, garbage-driven verify at
   worst. Fix direction (not applied): clamp every `cs + cl` (and
   every stored start+len) to `buf_len`, failing closed with 0.
2. `ecdsa_verify_der_sig` panics on over-long r/s INTEGERs —
   MEDIUM — filed #1057. `let r_off = 32 - r_len` (`:448`, same
   `:466` for s) goes negative for r_len > 32 while the copy loop
   `while ri < r_len and ri < 32` still indexes `r_bytes[r_off+ri]`
   (`:404`, `:450-453`, `:468-471`). Malformed peer signature with
   a 33+-byte (post-strip) INTEGER aborts the process instead of
   returning 0 — DoS via peer input. Legit P-256 zero-padded
   33-byte values strip to 32 and are unaffected (control probe).
   Fix direction: reject `r_len/s_len > 32` with 0 up front.
3. LOW (in-report, not filed): `:408` computes a bogus s-INTEGER
   position (`scs + scl - (scs - r_start - 1)`, off by 1-2) whose
   result is silently discarded at `:413` ("re-parse from scratch"),
   with dev-commentary ("Hmm...", "This is getting complicated...")
   left in. Dead code, result unused, bounded by der_read_tl checks
   — confusing but harmless. Mentioned for cleanup with #1057.

## Notes (no finding)

- OID bytes, tag constants, tbs span computation, BIT STRING
  unused-byte skips, RSA n/e zero-strip, EC 0x04/65-byte gate
  (`:476`) all trace correctly by review against the openssl
  anatomy.
- `der_read_tl` long-form caps at 4 length bytes; adversarial
  `cs + cl` i32 wraparound collapses into the same missing-clamp
  class as Finding 1 (one fix covers it).
- T13: offsets-only struct, no heap/Drop; raw borrows stay within
  the caller's buffer *if* Finding 1 is fixed.

Verdict: INCOMPLETE
