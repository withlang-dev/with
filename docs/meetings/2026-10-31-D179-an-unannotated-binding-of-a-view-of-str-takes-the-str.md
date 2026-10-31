# D179 — An unannotated binding of a view of `str` takes the `str`; `List` keeps observing (amends D144)

**Laws:** 1, 5 (docs/mission.md).

**Date:** 2026-10-31. **Status:** ruled by Eric ("A — `str` takes the value
by default. Keep `List` observing. Keep explicit views available. Preserve
resource ownership semantics. Require the ordinary `str` copy to remain
O(1)."). Issue #2859.

**Ruling.** An unannotated binding whose initializer denotes a place or
produces a view takes an owned value when the viewed type is plain-bits or
`str`. For `str`, this uses its ordinary O(1), reference-counted copy
semantics. For other types, the binding observes the place under D144. An
explicitly requested view remains a view and retains the usual borrowing
restrictions. Spec words in §3.8.

**Why.** `let s = parts[0]` with `parts: List[str]`, or `let name =
self.pool_resolve(sym)` (a `&str` result), bound a view and blocked every
later write of its root; the fix was `let s: str = …`, a type the compiler
already knew. D111 promises `str` copies everywhere (passing, collecting
— D142 — a temporary's view — D174); a binding from a durable place was
the one site where it still viewed. The fact that decides it is the one
D144 turned on: can a write be lost? D144 keeps `List` observing because
`Some(c) => c.push(9)` through a copy would silently drop the push. `str`
has no in-place mutation (built text goes through a builder), so a copy
and a view differ only in what a later write of the root may do, and
nobody reading `let name = …; self.pool.intern(other)` expects `name` to
change. Swift, Go, Mojo, Python and Java bind their value strings by
value; Rust moves or borrows; Zig copies a slice header. The rule is
stated over value-copy semantics, O(1) copying and no observable in-place
mutation — never "no in-place mutation" alone, which would reach an
immutable resource with identity and `Drop`.

**The lesson recorded.** Drop glue is an implementation property, not a
reason to impose ownership ceremony on the programmer. A reference-counted
string is a value; its implementation's complexity does not decide how an
ordinary binding behaves.

**Cost.** A `str` binding that was a free view becomes a retain/release
pair (atomic) unless last-use elides it, and an indexed element or a
`&str` result cannot generally be moved out of its owner. Accepted: the
default is clarity; a hot path spells the view (`let name =
&self.pool_resolve(sym)`). The landing PR measures Sema's hot paths
(benchmarks-check) and distinguishes previously annotated sites, which
already paid the copy, from previously unannotated views, which start to.

**Consequence.** Sema: `type_is_plain_bits` gains a sibling predicate
(`type_takes_value_on_binding`: plain bits or `str`), used wherever the
D144 binding rule is applied; the owned copy is established while the
source is alive (the contextual Copy adjustment materializes the pointee
at the binding, D22 §6.2). Fixtures: `behav_d179_str_binding_takes_value.w`
(`let s = parts[0]` then growth and element replacement; `let s =
self.pool_resolve(sym)` then pool reallocation; `let s = lines[i]` then
`lines.clear()`), `err_d179_explicit_str_view_conflict.w` (a written `&`
still refused across a write), a resource-binding fixture unchanged, all
under the debug allocator. Census pattern `str-view-copy-annotation` counts
`let x: str = <view of str>`; the sweep removes the annotations (514
`let x: str = …` in `src/` are the search space).

**Reopen if:** a `str` gains in-place mutation, or the retain cost on a
hot path cannot be recovered by spelling the view.

**Amendment (Eric, 2026-10-31, "carries a view clause is blessed").** A
plain-bits type that itself carries a view — a slice, a pointer, an
ephemeral value (a facade view token, an iterator), or a struct or payload
holding one — is not taken by value: the copy would still view its origin.
Found landing D172 PR B: applied literally, the rule copied a facade record
view and a byte-buffer view out of their resource and the §16.2b.7
invalidation checks went silent in five fixtures. Sema: `type_carries_view`
(the binding stays a view). Spec words in §3.8.
