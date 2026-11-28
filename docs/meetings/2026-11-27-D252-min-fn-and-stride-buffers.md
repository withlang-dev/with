# D252 — Implicit-length size-checked buffers (`min <fn>(param A)` and `stride ... table <TBL>[param F]`)

- **Date:** 2026-11-27
- **Status:** Delegated (D237 — settled by `docs/mission.md` Law 3, Law 5, Law 9; #3154, #3163)

## Context

Several C APIs take a byte/pixel buffer pointer without an accompanying byte
count parameter because another companion query function or image dimension
parameters determine the exact minimum required size:
- `protobuf-c`: `protobuf_c_message_pack(const ProtobufCMessage *msg, uint8_t *out)`
  requires at least `protobuf_c_message_get_packed_size(msg)` bytes in `out`.
- `libjpeg-turbo`: `tjCompress2`, `tjDecompress2`, and `tj3Compress8` require
  `stride * height` bytes (where `stride = pitch != 0 ? pitch : width * tjPixelSize[pixelFormat]`).

## Decision

Add two bounds-checked implicit-length forms to `FACADE_CLAUSE_BUFFER`:
1. `buffer param P len|capacity min <fn>(param A)` (modes 10/11): validates
   `buf.len() >= <fn>(param A)` in the generated bridge before calling C.
2. `buffer param P len|capacity stride param S width param W height param H table <TBL>[param F]`
   (modes 12/13): validates `W > 0`, `H > 0`, `S >= 0`, `0 <= F < TBL.len()`,
   `row = W * TBL[F]`, `stride = if S == 0: row else: S`, `stride >= row`, and
   `stride * H <= buf.len()` before calling C.

## Mission fit

- **Law 3 (Memory Safety Without Suffering):** *Test: Can safe code produce UB,
  use-after-free, data race, or silent leak?* No; every call checks exact buffer
  bounds before passing a pointer to C.
- **Law 5 (The Signature Is the Contract):** *Test: Can a reader determine
  ownership, borrowing, mutability, and fallibility from the signature alone?*
  `[]u8` / `[]mut u8` slices make direction and mutability explicit.
- **Law 9 (First-Class C Interop):** *Test: Does calling a modeled C library
  require `unsafe`, a manual wrapper, or a foreign build step?* No.
