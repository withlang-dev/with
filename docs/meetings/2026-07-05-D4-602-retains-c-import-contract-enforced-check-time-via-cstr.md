# D4 — #602: `retains:` c_import contract, enforced check-time via cstr_in modeling

**Laws:** 6, 4 (docs/mission.md).

**Date:** 2026-07-05
**Status:** Accepted
**Issue:** #602 · **Spec:** §16.3c · **Deciders:** Eric (BDFL)

### Decision

A c_import param can be annotated `retains: ["fn(idx)"]` — the callee keeps the
passed C-string pointer past the call. Such a param is a **modeled** C-string
input (`cstr_in`: callable without `unsafe`, a pointer into caller-owned storage
is accepted), but a call-scoped `str` temporary is **rejected** at check time
with guidance to pass `to_cstring()?.as_cstr().ptr()`. Params are borrowed by
default; only `retains:` marks retention.

### Why this shape (the "unreachable" detour)

A first pass built the store + enforcement but found it *unreachable*: the
`str→*const c_char` coercion only fires for `cstr_in`-modeled functions, and
`cstr_in` modeling came exclusively from the hardcoded `ci_overlay_cstr_in_param_count`
list — all borrowed, none retaining, not user-extensible. The fix was NOT to
defer but to make the finding the design: **`retains:` itself is the cstr_in
evidence.** A retained `const char*` param becomes a modeled cstr_in param (so
`ci_function_requires_raw_abi` no longer marks it raw) whose retention is
enforced at the coercion site (SemaCheck) — rejecting the `str`, accepting an
owned pointer. This makes the whole feature reachable and testable with pure
user code, no dependency on a real retaining libc function.

### Reasoning

- **Go cgo** documents a pointer-retention contract and enforces it dynamically
  under `cgocheck`; **We** enforce it statically at the coercion boundary
  (compile-time, zero runtime cost) with the `dbg_scribble` debug allocator as
  optional runtime teeth. Adopted the contract-with-teeth idea; rejected Rust's
  docs-only unsafe (no guardrail) and Zig's fully-manual approach.
- Mission "modeled C becomes humane, with guardrails": the annotated surface
  stays zero-ceremony for the borrowed common case; the guardrail appears only
  when a param actually retains.

### Consequences

- Sema `retained_extern_params` (name_sym → retained-param bitmask), populated by
  a reader over c_import `retains:` records.
- `ci_function_requires_raw_abi` treats a retained const-c-string param as a
  modeled cstr_in param.
- Enforcement at the SemaCheck c-char coercion site.
- The curated overlay is the `retains:` clause itself (user-extensible); a real
  retaining libc function can be seeded there if one is identified.

---
