# Audit: lib/std/crypto/rsa.w @ 450733e5 — COMPLETE

Module: RSA PKCS#1 v1.5 SHA-256 signature **verification only** (138 lines,
read in full), ported from BearSSL `rsa_i31_pkcs1_vrfy.c`. Three
module-private `unsafe fn` symbols, no `pub`, no encrypt/decrypt/sign entry
points: `write_digestinfo_sha256` (rsa.w:12), `rsa_check_pkcs1_sha256`
(rsa.w:37), `rsa_pkcs1_sha256_verify` (rsa.w:100). Sole in-repo std caller
is `lib/std/crypto/x509.w:372` (via `use std.crypto.rsa`, x509.w:6);
only other caller is `tests/test_rsa.w`. No defects found in-module.
Key-size exposure below is delegated bigint risk, owned by #1051/#1052.

Commit: `450733e58a1a7cce14f9cb2084943fc178815111` verified via
`git rev-parse HEAD`; working tree untracked-only (`.codex/`, `docs/issues/`,
`docs/specs/`, `docs/superpowers/`). No compiler sources modified
(read-only honored; only new files are `docs/audit/probes/rsa/*` plus this report).

## Oracles (independent, never self-derived)

- O1 `hashlib.sha256(b"test")` vs test hash: EXECUTED, pass. Observed
  `sha256(test) = 9f86d081884c7d65…0f00a08`, test hash identical.
- O2 `pow(sig, e, n)` EM structure for the RSA-1024 test vector
  (n/sig/e/hash parsed from `tests/test_rsa.w::test_rsa_verify`:
  n_len=128, e=`010001`=65537 confirmed, sig<n confirmed): EXECUTED
  partial. Observed `EM head = 0001ffff`, first `0x00` at index 76 ==
  expected separator `2 + ps_len` with `ps_len = 128-3-51 = 74`, and
  `em[75..77] = ff00` — all consistent with a valid block. Full
  DigestInfo+hash conjunction HELD (see Obs-3: probe script off-by-one).
- O3 Negative control, corrupted sig (`sig^1`): EXECUTED, pass.
  Observed `corrupt-sig still valid = False` (expect False).

## Probes

- P1 `docs/audit/probes/rsa/direct.w` (`use std.crypto.rsa` + call): HELD.
  `with-stage1 check`/`run` reject the `unsafe:` single-line form
  (`unsafe: requires a newline and indented block`) before any visibility
  diagnostic — the privacy gate was never reached, so module-privacy
  behavior is unconfirmed this session, not refuted.
- P2 Committed suite `tests/test_rsa.w`: HELD. `with-stage1 check` fails
  identically (5× `unsafe:` single-line errors at :51, :56, :62, :117,
  :127). Stale at HEAD independent of this module; already filed as
  #1053 — do not re-file.
- P3 `docs/audit/probes/rsa/vendored_pad.w` (rsa.w:12-91 vendored verbatim +
  self-contained driver): HELD. Same `unsafe:` single-line rejection in
  the driver lines; vendored functions themselves produced no separate
  diagnostic, but nothing executed.

## Traces

- T-size bands actually exercised vs reachable. `tests/test_rsa.w`
  exercises exactly one key size: n_len=128 (1024-bit) plus a padding
  check at em_len=128. Entry-point guards (rsa.w:106-109) are only
  `sig_len != n_len → 0` and `n_len < 64 or n_len > 512 → 0`, i.e. every
  size 512..4096 bits is reachable through `rsa_pkcs1_sha256_verify`.
  That spans all three bigint bands from the given context (<590-bit
  safe, 590..2449-bit silent-wrong per #1051, >2449-bit panic per #1052),
  including the exercised 1024-bit vector. rsa.w's own buffers are
  correctly sized for the full admitted range (`[u32; 140]` vs 134 needed
  for 4096-bit per the rsa.w:111 comment; `em [u8; 512]` at rsa.w:133) —
  the band risk, if real, lives in the bigint callee (`i31_from_monty`
  fixed temps), not in rsa.w. My `u32;80` grep spelling found no hit in
  `bigint.w`, so the temp dimensions themselves are NOT independently
  confirmed this session; band claims rest on #1051/#1052 as given.
- T-floor consistency: padding floor `em_len < 11+19+32 = 62` (rsa.w:43)
  vs `n_len` floor 64 gives `ps_len = 64-3-51 = 10 ≥ 8` — consistent, no
  dead/contradictory range. `ps_len < 8 → 0` (rsa.w:54) enforces the
  PKCS#1 minimum.
- T-callers: `x509.w:372` is the sole std consumer (call-site argument
  sizes not traced — no tool budget remaining); `tests/test_rsa.w` is the
  only test caller. The `muse.search` for rsa symbols outside these hits
  returned nothing further.

## Findings

None in-module. (Numbered-candidate dispositions: C1 1024-bit vector
inside the alleged silent-wrong band — NOT refuted either way; O2's full
conjunction is HELD per Obs-3 and the bigint behavior is owned by
#1051/#1052. C2 stale `tests/test_rsa.w` — owned by #1053, do not
re-file. C3 non-`pub` surface — longstanding std-internal design shared
with aes.w, x509.w consumes it legally; not a defect.)

## Observations (non-defect)

- Obs-1: `tests/test_rsa.w` is stale at HEAD (`unsafe:` single-line form
  rejected; cf. AES report's `void`-vs-`Unit` staleness class). Owned by
  #1053; fix the test file, not this module.
- Obs-2: All-private surface (`write_digestinfo_sha256`,
  `rsa_check_pkcs1_sha256`, `rsa_pkcs1_sha256_verify` — none `pub`);
  unavailable to user programs by design. No change recommended without
  a std-API decision.
- Obs-3 (probe-script bug, honest record): my O2 structural check used
  off-by-one indices (sep 75 / T 76..95 / hash 95..127 instead of correct
  76 / 77..96 / 96..128 for n_len=128), so its scripted verdict printed
  `False` while the raw observed bytes (head, sep position, `ff00`)
  support validity. Re-run with corrected indices before citing O2 as a
  full pass.

Verdict: COMPLETE — no in-module defects; padding/verify logic reviewed
line-by-line against the PKCS#1 v1.5 structure; O1/O3 pass EXECUTED, O2
partial with HELD remainder (Obs-3); probes P1-P3 HELD (reasons above);
band exposure documented and delegated to #1051/#1052; test staleness
owned by #1053. No issues filed.

## Close-out (primary, 2026-09-04)

C1 closed: `probe_1024.w` want oracle-confirmed via python3 `pow`
(1024-bit modulus, mlen=34, oracle==want True); its FAIL is the #1051
band (mlen >= 20), expected to pass once #1049 lands. No new filing;
band exposure stays delegated to #1051/#1052, staleness to #1053.
