# D63 — One callable type: `fn(A) -> R` carries compiler-tracked environment ownership; not `Copy`

**Date:** 2026-09-23. **Status:** BDFL ruling (Eric: "Rule (A) … environment
ownership is one more such property"). §12.4 "The callable type" carries the
text. Resolves the type question D62 left open (#1567).

**Decision.** A function, a non-`move` closure and a `move ||` closure all
have type `fn(A) -> R`; the compiler tracks which, as it tracks
`may_suspend` (§14). A non-`move` closure is ephemeral; a `move ||` closure
owns its environment (inline when every capture is `Copy`, otherwise a heap
cell owned by the value, freed on drop with captured `Drop` values
destroyed then) so a struct holding one has `Drop`; a consuming closure is
call-once. Four consequences written down so they are not improvised:
(1) `fn(A) -> R` is not `Copy`, bare functions included — `Copy` is a
property of the type, not of a value's provenance, or generic code cannot
reason about it; `.clone()` is free for bare/view callables and needs every
capture `Clone` for owned ones; calls through a binding or field do not
move; the use-after-move diagnostic suggests `.clone()` or calling through
the original. (2) Call-once crosses a signature: a consuming closure may
only go to a callee that invokes it at most once — proven from the body in
one compilation; across a bundle boundary the default is "any number of
times" and the closure is rejected until a `once` parameter annotation
exists (deferred; same cross-bundle shape as `-> &T` in §3.4). (3) Views
flow like `&T` parameters: a non-`move` closure argument is ephemeral in
the callee (Rule 8) — callable, passable, not storable/returnable/capturable
by a `move ||` closure; this closes §13.1's erasure hole. (4) Performance
is an optimizer commitment: a call through the pair is indirect unless the
compiler specializes, and it does when a closure literal reaches a
parameter within one compilation (Swift's devirtualization); only a
captureless closure coerces to an `extern "C"` pointer.

**Alternative rejected.** (B) A second spelling for owned closures
(`Closure[A, R]`, `own fn`, or a trait — Rust's shape with one trait
instead of three). It puts in the user's hands a distinction the compiler
learned from `move ||` two tokens earlier, and splits every higher-order
API table in the spec. Rust monomorphizes each closure as its own type;
Swift and Go have the one thick/fat type and pay with refcount/GC; With
keeps the one type and proves the environment's lifetime instead.

**Surprise to expect.** Rust makes fn pointers `Copy`; here `let g = f`
moves `f`. The §11/§13 callback examples (`f: fn(StrView)` parameters)
already conform; no spec example holds a callable in a struct field.

---
