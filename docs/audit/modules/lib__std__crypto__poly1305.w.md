# Primary verification — `lib/std/crypto/poly1305.w`

Status: **INCOMPLETE** (does not compile; owned by filed #1054)
Primary verifier: primary (full source read + attempted execution)
Source revision: `450733e5`
Source examined: all 168 lines (single complete read)

## Scope examined

Poly1305 MAC (RFC 7539): context create/update/finish. All symbols
module-private. Sole in-std consumer: `chacha20poly1305.w` AEAD path.

## Behavioral matrix

- `with-stage1 check` on any file doing `use std.crypto.poly1305`
  → sema errors, first at poly1305.w:113
  (`cannot assign an owned value to a reference-typed binding` for
  `h1 = h1 & 0x03FFFFFF`), same class through `:112-126,143-149`.
  EXECUTED (this session; also observed under stage2 per the AEAD
  report). No behavioral probe is possible until it compiles —
  execution HELD for all vectors.
- Static trace (review only, not a pass claim): clamp/mask
  structure follows the RFC 7539 accumulator shape; the defect is
  purely the reference-typed `var hN = ctx.h[N]` bindings vs the
  current checker (minimal repair `var h0: u32 = …`, not applied).
- Embedded-stdlib copy verified byte-identical to working tree
  (per AEAD report diff).

## Findings

Owned by #1054 ([crypto] AEAD path dead: entry not pub +
poly1305_finish rejected) — do not re-file. No separate findings.

Verdict: INCOMPLETE
