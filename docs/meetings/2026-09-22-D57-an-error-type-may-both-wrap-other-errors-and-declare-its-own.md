# D57 — An error type may both wrap other errors and declare its own variants

**Laws:** 1 (docs/mission.md).

**Date:** 2026-09-22. **Status:** BDFL ruling (Eric); §10.9 carries the
blessed sentence.

**Decision.** `error E from A, B =` followed by variants joins §10.8 and
§10.9: the listed types get generated wrapper variants and `From`
conversions (so `?` converts), and the written variants are the type's own.
A written variant whose name equals a generated wrapper's name is a
compile-time error — the compiler never picks between two meanings.

**Why.** Before this, a type could either convert automatically or have
its own variants; a service error with both (`Validation`, `TimedOut`,
`Cancelled` beside wrapped `DbError`/`CacheError`) had to convert by hand
at every call site. Joining the two existing forms is the smallest change
and generates exactly what one meaning forces (mission.md). Zig merges an
own error set with others (`A || B`) the same way, without payloads; Rust
leaves it to hand-written `impl From` or the external `thiserror`.

**Held (option C).** A user-implementable `From` trait, for conversions
that are not plain wrapping (e.g. mapping one variant onto another), waits
until a real program needs one. `From` is not a user-writable trait today.

**Reopens if** such a program appears.

---
