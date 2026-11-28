# D251 — Out-allocated owned byte buffers (`buffer out param P len param L freed by F`)

- **Date:** 2026-11-27
- **Status:** Delegated (D237 — settled by `docs/mission.md` Law 3, Law 5, Law 9; #3154)

## Context

Many C libraries allocate an output byte buffer internally and return both the
pointer and its length through out-parameters, requiring the caller to release
the pointer with a library deallocator — for example TurboJPEG's `tjCompress2`,
`tj3Compress8`, and `tj3GetICCProfile` (`unsigned char **jpegBuf, size_t *jpegSize`,
freed by `tjFree`/`tj3Free`).

## Decision

Add `buffer out param P len param L freed by F` (`FACADE_CLAUSE_BUFFER` mode 9):
- `P` is a mutable pointer to a byte pointer (`*mut *mut u8` / `*mut *mut i8`),
  `L` is a mutable pointer to an integer length, and `F` is a single-parameter C
  deallocator.
- Both `P` and `L` leave the presented parameter list; the compiler-generated
  bridge passes local null/zero slots, copies `0..len` into an owned `List[u8]`
  on success, releases the C pointer with `F` on both success and `ok` failure,
  and returns `List[u8]` (inside `Result[List[u8], E]` under `ok`).

## Mission fit

- **Law 3 (Memory Safety Without Suffering):** *Test: Can safe code produce UB,
  use-after-free, data race, or silent leak?* No; C's allocation is copied into
  an owned `List[u8]` and freed on every exit path, including error returns.
- **Law 5 (The Signature Is the Contract):** *Test: Can a reader determine
  ownership, borrowing, mutability, and fallibility from the signature alone?*
  `Result[List[u8], ...]` states ownership and fallibility directly.
- **Law 9 (First-Class C Interop):** *Test: Does calling a modeled C library
  require `unsafe`, a manual wrapper, or a foreign build step?* No.
