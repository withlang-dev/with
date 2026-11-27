# D243 — Writable by-value capacity buffers (`buffer param P capacity param L`) and positioned `of R(param N)`

**Laws:** 1, 4, 6, 9, 11 (`docs/mission.md`).

**Date:** 2026-11-27. **Status:** delegated under D237 (#3138). Spec words in `docs/spec/031_contract-language.md` and `docs/spec/016_ffi.md`.

**Context.** Completing `registry/c/bzip2/facts.with` (#3138) exposed two general C API shapes already partially anticipated by D64 and D209:

1. **Writable output buffer with by-value capacity:** `int BZ2_bzread(BZFILE *b, void *buf, int len)` and `int BZ2_bzRead(int *bzerror, BZFILE *b, void *buf, int len)` (also `gzread`, `read`, `recv`). `buf` is a writable pointer and `len` is a by-value integer capacity; C writes up to `len` bytes into `buf` and returns the count (or an error code). D64 ruled `buffer param P len param L` (read-only `[]u8`) and `buffer param P capacity param L inout` (writable `[]mut u8` with `*mut Int` copy-back), noting that `capacity … inout` left room for non-inout capacities.
2. **Lent operation with resource at parameter `N != 0`:** `BZ2_bzRead(int *bzerror, BZFILE *b, void *buf, int len)` and `BZ2_bzWrite(int *bzerror, BZFILE *b, void *buf, int len)` put an out-pointer (`param 0 discarded`) before the resource handle (`BZFILE *b` at param 1). D209 ruled `drop f(param N)`, `destroys f(param N)`, and `abandon f(param N)` for destroyers at another position; `of R` on lend operations still hardcoded parameter 0.

**Mission fit (D237).**

- **Law 1** (*The compiler never asks for what it already knows.*): *Test: does this make the programmer state something the compiler can establish, or something with no consequence?* No: whether C only reads `buf` (`len` -> `[]u8`) or writes into `buf` (`capacity` -> `[]mut u8`) is not determined by `void *buf, int len`, so the contract spells it once; callers then pass a single `[]mut u8` slice with zero `unsafe`. Likewise, `of R` omits `(param 0)` when the resource is first and spells `of R(param N)` only when it is not.
- **Law 4** (*A fact is inferred only when being wrong cannot create unsafety.*): *Test: what happens if this inference is wrong?* Nothing is inferred. `buffer param P capacity param L [elements]` requires a non-const pointer `P`, a by-value integer `L`, and a runtime range check that `P.len()` fits in `L`. In With, `[]mut u8` (and `[]mut T` for flat `T`) always points to initialized memory, so C writing `0..=L` bytes leaves the slice valid regardless of C's return value. `of R(param N)` is verified by Sema to receive `R`'s representation at `N`.
- **Law 6** (*The signature is the contract; the body is evidence about the body only.*): *Test: is the programmer promising something to a reader who cannot see the body? Then spell it. Otherwise never.* Both clauses spell the boundary contract explicitly in the `c contract` block (`[]mut u8` vs `[]u8`, and which parameter receives `self`).
- **Law 9** (*Delete the old route once the better one exists.*): *Test: is this route still the unique way to say something, or a habit?* Uses the exact existing grammar families: `capacity param L [inout]` (D64) and `of R[(param N)]` paralleling `drop`/`destroys`/`abandon f[(param N)]` (D209).
- **Law 11** (*The compiler guarantees safety, not correctness of intent.*): *Test: is this needed to keep a guarantee, or does it only protect the programmer from themselves?* Returning C's own return value unchanged on `buffer param P capacity param L` preserves full memory safety without policing C's error-code conventions (`-1`, `0`, `ssize_t`, etc.).

**Decision.**

1. `buffer param P capacity param L [elements]` (without `inout`) pairs a writable pointer `P` with a by-value integer `L`, rendering `[]mut u8` (or `[]mut T` with `elements`), bounds-checking `P.len()` into `L`'s C integer type before the call, and leaving the C return value unchanged (or projected under `ok`). A `const` pointer `P` is refused.
2. `of R(param N)` hosts a lend operation on resource `R` receiving `self` at parameter `N` (defaulting to parameter 0 when `(param N)` is absent), bridging all remaining parameters around `N` and projecting `self` to presented parameter 0 for call effects and D215 C-name forwarders.
