# D240 — Retained variadic case naming a pointer-wrapping facade resource `&R` (delegated)

**Laws:** 4 (ownership, retention and lifetime come from a clause, a profile
or a proof, never from a name); 1 (one mechanism per concept — reuses D194's
retained-borrow window).

**Date:** 2026-11-26. **Status:** delegated under D237 / D98 (direction ruled
in D235 #3120; exact §16.2b.5 sentence settled by mission.md). **Issue:** #3120.

## Decision

A retained variadic case (§16.2b.5) may name `&R`, a shared borrow of a facade
resource whose representation is a pointer (for example
`case CURLOPT_HTTPHEADER: &HeaderList retains by param 0 until curl_easy_reset`).
The call passes the borrowed resource's representation (`value.repr`), and the
retaining resource holds a shared borrow of it for D194's retention window
(§16.2b.9):

- Two handles may retain a shared borrow of the same resource (for example two
  libcurl `Easy` handles sharing one `HeaderList`).
- While any handle holds the borrow, the borrowed resource cannot be dropped,
  moved, or passed to an operation that consumes it or whose contract does not
  mark that parameter `preserves`.
- Operations marked `preserves` remain callable while the borrow is held.
- Once every retaining handle releases the retention (`until`, `abandon`, or
  destruction), non-`preserves` operations and moving/dropping the resource
  succeed again.
- A retained case naming `&R` where `R` does not wrap a pointer, or combining
  `&R` with `length param`, is a compile-time error.

## Spec

`docs/spec/016_ffi.md` §16.2b.5 ("Retained pointer cases"), v7.96.
