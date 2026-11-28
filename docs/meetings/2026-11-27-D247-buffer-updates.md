# D247 — `buffer param P len|capacity param L updates` for streaming in-out buffer counts (delegated)

**Date:** 2026-11-27. **Status:** delegated under D237 (mission-settled; Eric vetoes by revert).

**Laws:** Law 1 (*The compiler never asks for what it already knows*), Law 4 (*A fact is inferred only when being wrong cannot create unsafety*), Law 5 (*Observing is not owning; transport is not duplication*), Law 10 (*The mission is tested, not described*), Law 12 (*The programmer has the last word on what the compiler cannot see*).

---

## Question

Streaming C compression and transcoding APIs routinely pass counted buffers whose byte/element counts are updated in place through `*mut size_t` / `*mut int`, often with **two** buffers in the same call and a non-status return value (such as a streaming hint or byte count):

- `size_t LZ4F_decompress(LZ4F_dctx *dctx, void *dst, size_t *dstSizePtr, const void *src, size_t *srcSizePtr, const LZ4F_decompressOptions_t *opts)` (`c.lz4`, #3137) — updates `*dstSizePtr` (bytes written) and `*srcSizePtr` (bytes consumed), returning `0` when the frame ends, a positive byte hint while streaming, or an error tested with `LZ4F_isError`.
- `size_t LZ4F_getFrameInfo(LZ4F_dctx *dctx, LZ4F_frameInfo_t *info, const void *src, size_t *srcSizePtr)` (`c.lz4`, #3137) — fills `*info` and updates `*srcSizePtr` with header bytes consumed.
- `int LZ4_compress_destSize(const char *src, char *dst, int *srcSizePtr, int targetDstSize)` (`c.lz4`, #3137) — updates `*srcSizePtr` with input bytes consumed and returns compressed bytes written.

D64's `buffer param P capacity param L inout` models a single writable output buffer whose updated length replaces a void or single-`ok` status return (`Result[usize, E]`). It intentionally refuses `len ... inout` and refuses omitting `ok` when C returns a value.

Should WCL support `buffer param P len param L updates [elements]` and `buffer param P capacity param L updates [elements]` for buffers whose length pointer C reads and updates?

## Mission fit

- **Law 1:** *Test: does this make the programmer state something the compiler can establish, or something with no consequence?* Without `buffer ... updates`, streaming APIs like `LZ4F_decompress` cannot be presented safely, forcing user programs into `unsafe` raw pointers and manual bounds checks. With `updates`, callers pass ordinary slices (`[]mut u8`, `[]u8`) and receive bounds-checked `usize` counts.
- **Law 4:** *Test: what happens if this inference is wrong?* Nothing is inferred; the contract states the buffer/count pairing explicitly with a header citation, and the generated bridge runtime-checks `0 <= count <= slice.len()` after C returns (panicking if C reports a count outside the slice's bounds).
- **Law 5:** *Test: does this operation create an owner the type system does not know about?* No; slices are borrowed for the call and updated counts are `usize` values.
- **Law 10:** *Test: what program would fail if this rule were quietly lost?* `test/behavior/behav_d247_buffer_updates.with` and `uat/lz4.uat`.
- **Law 12:** The contract author states the bounds relationship; the compiler honors and verifies it.

## Decision

Add `buffer param P len param L updates [elements]` and `buffer param P capacity param L updates [elements]` (paralleling D244's `updates` and D64's `inout`):

- `P` is presented as `[]T` (`len`) or `[]mut T` (`capacity`).
- `L` must be `*mut <int>`; the bridge initializes a local to `P.len()`, passes `&raw mut count` to C, bounds-checks `0 <= count <= P.len()` after C returns (panicking on violation), and appends `count as usize` to the operation's returned tuple (joining C's return value, any `fills` outputs, and any `ok` status contract under the same composition rule as `fills`).
- Existing `buffer param P capacity param L inout` semantics and diagnostics remain unchanged.
