# Audit: lib/std/crypto/chacha20.w @ 450733e5

Scope: read-only source audit of the ChaCha20 stream cipher module (70 lines).
Commit: 450733e5. Oracle policy: crypto correctness against INDEPENDENT
oracles only (system openssl 3.6.3, RFC 8439 vectors); never self-derived.

## Module summary

- `qr` (l5-21, private): quarter round. `a+=b; d^=a <<<16; c+=d;
  b^=c <<<12; a+=b; d^=a <<<8; c+=d; b^=c <<<7` with wrapping `+%=`.
  Matches RFC 8439 section 2.1 exactly (op order and rotation constants
  16/12/8/7 all correct).
- `chacha20_block` (l23-56, private): constants `expand 32-byte k`
  (0x61707865/0x3320646e/0x79622d32/0x6b206574), key bytes 0..31 LE into
  state[4..12], counter into state[12], 12-byte nonce LE into state[13..16],
  10x (4 column + 4 diagonal) rounds with the exact RFC 2.3 column schedule
  (0,4,8,12)(1,5,9,13)(2,6,10,14)(3,7,11,15) and diagonal schedule
  (0,5,10,15)(1,6,11,12)(2,7,8,13)(3,4,9,14), add-back of original state,
  LE serialization. All conformant.
- `chacha20_crypt` (l58-70, private): per-64-byte keystream XOR from
  caller-supplied counter, wrapping `ctr +%= 1`, partial trailing block via
  `chunk`, in-place. Correct; `len <= 0` is a no-op via loop guard.

## T13 ownership/drop: CLEAN

No owned values, no heap, no cross-function borrows. Stack arrays
(`state`, `working`, `block`) accessed via `&raw mut` pointers confined to
each function body. `working[i] +%= state[i]` reads a distinct array (no
aliasing). Nothing to drop; no lifetime hazard.

## T15 migration fidelity: CLEAN

No stale idioms (`&mut`, `rotl32`, `-> void`: grep empty). `&raw mut`,
wrapping `+%=`, `.rotate_left(n)` all accepted: `with-stage1 check
lib/std/crypto/chacha20.w` returns `ok` (probe EXECUTED). Behavior vs the
pre-migration original (dd11031e, BearSSL port using `rotl32`/`+%`) is
preserved: same constants, same round schedule, wrapping add in both.

## T22 spec conformance: CONFORMANT (algorithm), COVERAGE STALE (tests)

Algorithm verified against independent oracle (see P1). No spec defect found
in the module. Findings below concern test coverage, not the cipher.

## Findings

1. [MEDIUM] Claimed RFC-vector coverage in tests/test_crypto.w:117-132
   (`test_chacha20`) does not compile, so it never executes. Verified the
   file exists. `with-stage1 test tests/test_crypto.w` (stage1 @450733e5)
   and `out/release/bin/with test` (release @c83b13f66) both fail, first at
   `tests/test_crypto.w:12` (`-> void` rejected; `Unit` required). A /tmp
   copy with `void`->`Unit` plus the missing `use
   std.builtins.int_to_string` (§18.1 prelude gate) then fails further with
   `chacha20_block is private to module` and an owned-value assignment
   error — the staleness is layered, not a one-token fix. Refutation attempt
   vs landed intent: docs/completed/port_bear_ssl.md:16 claims "all pass RFC
   8439 test vectors"; that claim is stale at this commit because the test
   file cannot build. Survives refutation. Probe status: EXECUTED (oracle:
   the compilers themselves).
2. [LOW] Even if built, tests/test_crypto.w:128-132 asserts only 4 of the 64
   keystream bytes (`10 f1 e7 e4`). The 4-byte prefix does discriminate
   (openssl wrong-IV controls below yield `b826...` / `8adc...`), so this is
   a strength gap, not a soundness hole. Recommend asserting the full block
   from the P1 oracle string. Probe status: EXECUTED (oracle: openssl).
3. [INFO, not this module's defect] The sole in-std caller,
   lib/std/crypto/chacha20poly1305.w:11,16, legally reaches the private fns
   (std internal-boundary sharing per src/Sema.w:1382-1387; `check` of the
   AEAD module reports 0 privacy errors), which refutes any dead-code claim
   against `chacha20_block`/`chacha20_crypt`. The AEAD module as a whole
   currently does not build due to 16 owned-value errors all located in
   poly1305.w:113-149 (a neighbor module, out of scope here). Probe status:
   EXECUTED.

## Probes run

- P1-oracle (EXECUTED, oracle: system openssl 3.6.3, independent):
  `openssl enc -chacha20 -K
  0001...1f -iv 01000000000000090000004a00000000 -nosalt` over 64 zero bytes
  (IV = counter 1 LE + RFC 8439 §2.3.2 nonce 000000090000004a00000000) emits
  `10f1e7e4d13b5915500fdd1fa32071c4c7d1f4c733c068030422aa9ac3d46c4ed28264
  46079faa0914c2d705d98b02a2b5129cd1de164eb9cbd083e8a2503c4e` — the full
  64-byte RFC 8439 §2.3.2 keystream, prefix-matching the in-repo `10 f1 e7
  e4` assertion. Negative controls: IVs `0000000100...` and `0000000000...`
  yield `b82649fc...` and `8adc91fd...` respectively (oracle discriminates).
- P2-direct-exec (HELD): `docs/audit/probes/chacha20/probe_src.w` (P1-P4:
  full-block dump, counter separation, 128/100-byte crypt roundtrips,
  flipped-key-bit negative control) could not execute — the module exposes
  no `pub` fn and Sema rejects every user-tier caller (verified via `run`,
  `test`, and `-e`: `symbol 'chacha20_block'/'chacha20_crypt' is private to
  module`). The only legal std caller is blocked by finding 3. No execution
  path exists without editing repo sources (forbidden) — hence HELD, with
  correctness carried by P1 + the line-by-line spec trace above + clean
  `check`.
- P3-check (EXECUTED): `with-stage1 check lib/std/crypto/chacha20.w` → `ok`.
- P4-aead-check (EXECUTED): `check chacha20poly1305.w` → 16 errors, all in
  poly1305.w, 0 privacy errors (proves std reachability of chacha20 fns).
- P5-in-repo-callers (EXECUTED): repo-wide grep finds the only callers are
  chacha20poly1305.w:11,16 and tests/test_crypto.w:127. No other dispatch
  sites.

## Verdict

Verdict: COMPLETE — module correct; 3 findings (1 medium, 1 low, 1 info), no cipher defect, no issues filed.
