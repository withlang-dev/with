# D41 — Comparison operators derive from one primitive per family: `Ord.cmp(&self, &other)` backs `<`/`<=`/`>`/`>=`, `Eq.eq(&self, &other)` backs `==`/`!=`; fixed-name methods are overrides

**Date:** 2026-09-13
**Status:** Ruled by Eric (verbatim: "I rule for one Ord.cmp(self: &Self,
other: &Self) -> i32 backing all four ordered operators (and Eq.eq(other:
&Self) for equality), keeping the fixed-name methods as optional overrides,
and amend §11.7"). The §11.7 wording was blessed verbatim ("lgtm",
2026-09-14) and landed in `docs/with-specification.md` §11.7; the
implementation conforms on branch `c-algorithms-phase1`.

**Context.** §11.7 dispatched every comparison to a fixed method name
(`lt`, `le`, `gt`, `ge`, `eq`, `ne`) while `Ord` carried only
`cmp(self: &Self, other: Self)` and nothing wired `cmp` to `<`. A type
with `Ord` alone had no `<`; a generic `T: Ord` body could not compare two
`&T` views (`cmp` took `other` by value, and D22 §13.6 forbids an owned
demand through a view of a non-Copy `T`); and two views of a type with no
`lt` silently compiled to an ADDRESS comparison (#1137). The Phase 1
facades (SortedVec, BinaryHeap) compare views inside their comparators
and surfaced all three.

**Alternatives.** (a) Keep six fixed methods and require `T: Ord` users to
write `lt`/`gt`… taking `&T` — six spellings of one fact, ceremony at the
character level. (b) `lt` as the single primitive (Swift's `<`), deriving
the other three — one method, but a three-way `cmp` is what sorting and
ordered containers consume, so `<` would be derived from `cmp` anyway.
(c) `cmp` as the primitive with `other: &Self`, overrides optional — one
method gives all four (and `eq` gives both equalities), both operands are
observed (D5: a function that observes takes `&T`), and a type that wants
a cheaper `<` keeps the override.

**References.** Rust (`PartialOrd::partial_cmp(&self, &Rhs)`, `lt`…
provided defaults), Swift (`Comparable` requires only `<` over borrowed
operands, the rest synthesized), Mojo (`__lt__` + `__eq__`, the rest
defaulted), Vale (operators are named functions over `&T`; `!=` derived
from `==`). None takes the right operand by value; none asks for four
separate methods.

**Consequences.** Sema: with no fixed-name method on either operand type,
`<`/`<=`/`>`/`>=` select `cmp` and `!=` selects `eq`
(`operator_method_derived`); MirLower lowers `cmp(...) <op> 0` and
`not eq(...)`, flipping the ordering's sign when the primitive lives on the
right operand's type. `traits.w`: `Eq.eq` and `Ord.cmp` take `other:
&Self`; every impl in the tree conforms. A view of a type with neither
primitive nor override stays a compile error (#1137), never an address
comparison. Reopen if a future ruling makes `Ordering` an enum (then `cmp`
returns it and the derivation compares against `Ordering.Less`, unchanged
in shape).

---
