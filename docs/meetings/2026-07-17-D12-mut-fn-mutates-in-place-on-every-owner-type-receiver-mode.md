# D12 — `mut fn` mutates in place on every owner type; receiver MODE decides by-place semantics (primitives and str included)

**Laws:** 6, 5 (docs/mission.md).

**Date:** 2026-07-17
**Status:** Accepted — BDFL ruling. **Deciders:** Eric (BDFL)

### The decision

A `mut fn` receiver borrows the caller's place and mutates it in place for
**every** owner type — scalar primitives (`i32`, `u64`, `f64`, `bool`,
`char`, …), `str`, distinct/newtypes over them, and aggregates alike.
`extend i32: mut fn bump(): self += 1` works: `x.bump()` on a `var x`
mutates `x`. The lowering is a receiver-mode `PassMode::IndirectPlace`
(a pointer to the caller's slot) computed once by `compute_fn_abi` (D6) —
the same ABI aggregates already use — so no new mechanism is introduced;
the previous restriction to STRUCT/GENERIC_INST/ENUM owners was an
incompleteness, not a design.

**The governing principle: the receiver MODE decides by-place behavior, the
owner's type does not.** `i32` is `Copy`, but `mut fn` still borrows in
place, because mode wins over Copy-ness — exactly as it already does for
Copy structs. `f(x)` (by-value param) copies; `x.bump()` (`mut fn`
receiver) borrows. `move self` stays consuming/owned (not share-place);
plain `fn`/`&self` on a Copy scalar may pass by value (read-only, no
observable difference).

**Idiom:** the blessed use is domain verbs on distinct/newtypes
(`Health.damage(n)`, `Money.add(m)`), not bare `i32.bump()` — when there
is no domain meaning, prefer the operator (`x += 1`). The spec examples
lead with distinct-type domain modeling (the app-dev audience).

Rejected: **Option B** (keep rejecting `mut fn` on primitive/str owners
with an honest diagnostic + a §9.5 carve-out). B bends the spec to a
current ABI limitation — backwards from spec-leads-compiler — and denies
app devs an ergonomic the two closest references ship in their own
standard libraries.

### Context / why

`extend i32: mut fn bump(): self += 1` compiled to a callee-copy mutation
that never reached the caller; after D7 enforcement it became a loud but
MISLEADING compile error ("cannot assign to immutable variable"). Root
cause is one gate: `SemaDecl.w:1086 fn_param_uses_value_ref_abi` excludes
`str` (line 1089) and restricts IndirectPlace to aggregate owners
(line 1093), so primitive/str receivers fall through to by-value.

Reference filter (verified in .reference/ checkouts): **Swift**
`Integers.swift:327 public mutating func negate()` ships a mutating
method on a primitive in the standard library — and `extension Int {
mutating func }` is the near-exact twin of With's `extend i32: mut fn`.
**Rust** `core/num/mod.rs:720 pub const fn make_ascii_uppercase(&mut
self)` ships a `&mut self` mutating method on a primitive in `core`.
**Go** (`time.go:226 func (t *Time) stripMono()`) mutates via
pointer-receiver on a named type. Unlike D11's 3-2 split, this is
effectively unanimous that the mutation must reach the caller: every
reference that lets you attach a mutating method to a value/primitive
receiver makes it work.

Mission filter: §9.5 already promises "mut self mutates in place"
generically with no primitive carve-out — so this is spec-leads-compiler
(the spec is right, the impl was incomplete). Ergonomics-first wants
`hp.damage(30)` over `hp = Health(hp.value - 30)`. "Safe as Rust" is a
bar, not a compass — a by-place mutable receiver on a primitive is exactly as
safe (the borrow is exclusive for the call); nothing becomes silently wrong.

Builds on D6 (`FnAbi`/`PassMode` single source) and D7 (receiver-mode
keywords). It is independent of D5's now-superseded free-parameter default.
Sibling of D11 (both are
core-type surface rulings taken in-scope for v0.16.0 rather than
deferred).

### Scope / implementation

In v0.16.0 (maintainer: "do it right, now" — NOT deferred). Two shapes,
tracked as implementation issues under umbrella #644:
1. Scalar primitive owners → IndirectPlace (`i32*`-style): **#677**.
2. `str` / fat-pointer owners → IndirectPlace over the `{ptr,len}` fat
   pointer (distinct ABI shape; own drop/lifetime audit cell): **#678**.
Both gated on the `/drop-audit` matrix (value shape × control flow ×
ownership op × receiver mode) per the receiver-ABI-change rule.

### What would reopen this

A drop/lifetime cell that cannot be made sound for an exclusive by-place scalar
or fat-pointer receiver.

---
