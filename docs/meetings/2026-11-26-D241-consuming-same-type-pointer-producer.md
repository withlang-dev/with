# D241 — Consuming same-type pointer producer (`consumes param N` + `null status CONST`) (delegated)

**Laws:** 4 (no hidden ownership or invented status; contracts state every
fact); 2 (zero leaks, zero double-frees, no raw escape hatch needed).

**Date:** 2026-11-26. **Status:** delegated under D237 / D98 (direction ruled
in D235 #3121; exact §16.2b.4 / §31.5 / §31.8.3 wording settled by mission.md).
**Issue:** #3121.

## Decision

A direct-return pointer producer of resource `R` may state `consumes param N`
for a parameter receiving `R` (such as `curl_slist_append`, which takes
ownership of the list head and returns the new head, or `NULL` on failure
leaving the input list untouched), paired with `null status CONST`:

- `null status CONST` names the library's status value for a `NULL` return;
  the facade never invents a status, and omitting `null status` on a consuming
  same-type pointer producer is a compile-time error.
- The presented method is `move fn <name>(...) -> Result[R, E]`, where a
  non-`NULL` return yields `Ok(R)` and a `NULL` return yields
  `Err(E.FailedWithResource(CONST, resource: R))` (or `FailedWith<R>` under a
  shared facade error).
- Unlike an out-parameter failure's `Failed<R>`, the resource carried in this
  error is `R` itself in a **good state**: it owns the consumed input intact,
  admits every presented operation of `R`, and runs `R`'s `Drop` once if
  discarded.
- Dependent resources (which are ephemeral and cannot live inside an error)
  and stray `null status` clauses on non-consuming / non-producer functions
  are rejected at compile time.

## Spec

`docs/spec/016_ffi.md` §16.2b.4, `docs/spec/031_contract-language.md` §31.5
and §31.8.3, v7.97.
