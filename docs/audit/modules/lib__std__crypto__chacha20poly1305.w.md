# Audit: lib/std/crypto/chacha20poly1305.w @ 450733e5

Verdict: INCOMPLETE

Module: 46 lines, single entry point `chacha20_poly1305_encrypt` (encrypt-only
AEAD, RFC 8439). Read in full with dependencies `chacha20.w` (70 lines),
`poly1305.w` (168 lines), `endian.w` (65 lines). Embedded-stdlib copies
byte-identical to working tree (diffed `out/gen/compiler/EmbeddedStdlibData.w`
sections vs `lib/std/crypto/poly1305.w`, `chacha20poly1305.w` → IDENTICAL).

## T22 — spec conformance (static trace; execution HELD, see F1/F2)

Construction matches RFC 8439 §2.8 step-for-step: poly-key from ChaCha20 block 0
(`chacha20poly1305.w:11`, counter 0), first 32 bytes as one-time key (`:19`
via `Poly1305.new`), payload encrypted in place with counter 1 (`:14-16`),
MAC over AAD‖pad16‖CT‖pad16‖le64(aad_len)‖le64(ct_len) (`:23-44`). Padding
`(16 - (len % 16)) % 16` and empty-input skips are correct. No static deviation
found. Notes (not defects): 12-byte nonce assumed by `chacha20.w:34-35`; i32
lengths with no negative guard (stdlib-wide idiom); API is encrypt-only, RFC
decrypt/verify left to callers.

## T15 — migration fidelity: PASS

`309ed3c5` touched 3 sites in this file (`&mut` → `&raw mut`, current lines
10, 20, 41); diff is purely mechanical, no receivers or structural change.
Landed-commit intent ("identical MIR") consistent with file content.

## T13 — ownership/drop in this file: PASS

`var mac = Poly1305.new(...)` binds an owned value; `&raw mut` borrows
(`:10,20,41`) are output-parameter idiom with no moves or drops. The T13
defect is in the dependency (F2), which severs this module's MAC path.

## Findings

1. [High, T22] `lib/std/crypto/chacha20poly1305.w:7` — entry point not `pub`;
   externally uncallable. Whole dependency chain likewise sealed
   (`chacha20.w:23,58`, `poly1305.w:12,89,105` have no `pub`; sibling
   `sha256.w:142` shows the `pub` convention). Zero in-repo callers exist
   (grep over `lib/`, `tests/` finds only generated embedded copies), so the
   module is dead code. Probe HELD: `rfc8439_aead.w` blocked at sema with
   `symbol 'chacha20_poly1305_encrypt' is private to module
   '<embedded-std>/std/crypto/chacha20poly1305.w'`; oracle (node
   crypto/OpenSSL-backed RFC 8439 §2.8.2 vector: CT `d31a8d34…`, tag
   `1ae10b594f09e26a7e902ecbd0600691`, pt 114 B) generated but never fed to
   the module. Refutation attempt: intended-internal-use fails —
   `tests/test_crypto.w:10` imports the module for external testing and no
   caller reaches it any other way. STANDS.
2. [High, T13] `lib/std/crypto/poly1305.w:112-126,143-149` (compiler reports
   embedded lines 113-126, 145-149; copies identical) — `poly1305_finish`
   `var hN = ctx.h[N]` bindings are reference-typed under the current checker;
   all 15 carry/mask writes (`h1 = h1 & …`, `h2 +%= c`, …) rejected with
   `cannot assign an owned value to a reference-typed binding`. Any downstream
   import of the MAC path (including this AEAD module) fails to compile under
   stage1 and stage2. Probe HELD (same probe as F1; 15/16 residual errors are
   these). Oracle: n/a (sema block precedes vectors). Refutation attempt: no
   in-repo caller compiles around it — intra-stdlib caller `:46` fails with
   the same errors, `test_crypto.w:217` never builds (F3). Minimal repair
   direction (not applied, read-only): annotate owned copies
   (`var h0: u32 = …`). STANDS.
3. [Medium, T22] `tests/test_crypto.w:10,238-250` — claimed AEAD coverage
   absent (file EXISTS, verified): module imported but
   `chacha20_poly1305_encrypt` never called, no AEAD test in `main`; moreover
   the file does not compile at this commit (`:12` `-> void` rejected by
   stage1 and stage2). Oracle: n/a. Refutation attempt:
   `docs/completed/windows-bootstrap-status.md` claims `44/44 passed` — stale,
   predates `void` removal; current tree fails to build. STANDS.

## Probes run

- `docs/audit/probes/chacha20poly1305/rfc8439_aead.w` (RFC 8439 §2.8.2 vector:
  key `80…9f`, nonce `070000004041424344454647`, AAD `50515253c0c1c2c3c4c5c6c7`,
  114 B sunscreen plaintext) — HELD at sema (F1+F2); oracle named above.
- `docs/audit/probes/chacha20poly1305/neg_chacha_block.w` — EXECUTED: reproduces
  `symbol 'chacha20_block' is private…`, proving F1 is chain-wide, not
  AEAD-specific.
- `docs/audit/probes/chacha20poly1305/pos_sha256_control.w` — EXECUTED:
  `with-stage1 check` → `ok` for pub `sha256_hash`; full `build` reaches link
  (only the probe-local `with_eprintln` extern is unlinkable — harness
  limitation, no in-tree provider). Proves the harness resolves pub stdlib
  APIs; failures are specific to this module chain.

## Negative controls

- Pub-API control above passes sema; privacy errors fire only on the
  non-`pub` crypto chain.
- `out/bootstrap/bin/with-stage1` vs `out/stage/bin/with-stage2` agree on all
  verdicts (F3 void-rejection, F2 ownership errors reproduced under both).
- Oracle cross-check: node result reproduced published RFC values exactly
  (CT prefix `d31a8d34648e60db`, tag `1ae10b594f09e26a7e902ecbd0600691`),
  so the oracle itself is validated; it is the module side that cannot run.

Close-out (primary, 2026-09-04): F2 sema rejection re-executed
(`use std.crypto.poly1305` check fails at poly1305.w:113); F1/F3 stand.
Filed #1054 ([crypto] AEAD dead: entry not pub + poly1305_finish
rejected). F3 stale-test half covered by #1053.
