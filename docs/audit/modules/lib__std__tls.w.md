# Primary verification — `lib/std/tls.w`

Status: **INCOMPLETE** (3 filed: 1 High auth-omission, 1 Med-High
wire-bounds, 1 Low stale suite)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 832 lines (three complete reads)

## Scope examined

TLS 1.2 client: record I/O (`:39-109`), P_SHA256 PRF (`:114-170`),
conn state (`:174-224`), GCM send/recv (`:229-352`), ClientHello
(`:365-500`), ServerHello parse (`:503-531`), server-handshake
loop (`:536-619`), key derivation (`:622-666`), client finish
(`:669-744`), server finish (`:747-774`), connect (`:780-832`).
Reachable via `lib/std/http.w:174` (https path). Big stack arrays
(`ct/rec_buf` 16640, `seed_full` 256, `concat` 288) are all `u8`
(memset path — unaffected by #1049).

## Behavioral matrix

- `docs/audit/probes/tls/prf.w` (vendored PRF+HMAC+SHA-256):
  100-byte output byte-exact vs independent python P_SHA256
  oracle (multi-block, exercises A(i) iteration). EXECUTED PASS.
- AES-GCM/SHA-256/HMAC/ECDSA-verify primitives verified in
  their module audits (all COMPLETE). Correct but never asked
  to authenticate the peer (see F1).
- Wire-path attack probes HELD (require a peer; no stub harness
  in repo).

## Findings

1. HIGH — no authentication anywhere: zero verify calls in 832
   lines (grep-verified); EC/ECDHE points used unauthenticated
   (`:592-613`); server Finished accepted blind (`:773`, "for
   MVP just accept"). MITM-trivial; https path affected. Filed
   #1061.
2. MEDIUM-HIGH — wire lengths unclamped: `first_cert_len` vs
   hs_len (`:584-590`), `hs_len` vs record (`:555` guards header
   only; `:564` hashes and `:569-612` parse past it),
   `*cert_len = hs_len` vs 8192 cap (`:576-580`). Same escape
   class as executed #1056. Filed #1062.
3. LOW — `tests/test_tls.w` stale (`unsafe:` rejected at `:36`;
   same class as #1053/#1055). PRF logic itself verified (above).
   Filed #1063. Recorded-not-filed hardening notes: `data_len`
   vs 16640 `ct`, `hostname_len` vs 512 ClientHello `buf`,
   PRF label/seed vs 256 `seed_full` (internal callers safe
   today).

Verdict: INCOMPLETE
