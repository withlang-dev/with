# D145 — A range has `iter()` and its bounds are `start` and `end`; `Range[T]` is spellable in a generic signature (delegated)

**Laws:** 1, 2 (docs/mission.md).

**Date:** 2026-10-22. **Status:** delegated (D98): implemented on the
agent's prediction; Eric vetoes by revert. **Issue:** #2544 (from D142).

**Decision.** A range is a sequence, so D142's rule covers it: `(0..n) |>
map(it * 2)` iterates the range. The mechanism is the slice's (D142): a
std iterator, `RangeIter[T]` in `std.collections`, built by `range_iter` /
`range_iter_inclusive` over the range's bounds, with `impl[T: One + Ord]
Iter[T]`, dispatched by Sema for `r.iter()` and for a range on the left of
`|>`; `for` keeps its counter loop. For std to read the bounds, a range's
`start` and `end` are read-only fields (§4.7): Sema types them as the
element type and records the bound's index under the access node
(`range_bound_fields`, D65), MIR projects the range value's fields 0 and
1 as the membership lowering already did. `Range[T]` / `RangeInclusive[T]`
with a type parameter resolve in a generic signature (they were refused as
unknown types), and a range argument binds `T` from its element type.

**Context.** §4.7 said ranges "implement `Iter[T]`", which nothing did: a
range had no `iter()`, no `next()`, no fields, and a range in a pipeline
failed with "undefined variable" at `it`. §13.5 (D142) says a sequence on
the left of `|>` iterates by the `for` rule.

**What the others do.** Rust: `Range<T>` has public `start`/`end` and
implements `Iterator` directly (`Step` bound). Swift: `ClosedRange`'s
`lowerBound`/`upperBound`; a countable range is a `Collection`, so it has
an iterator. Zig has no range value. Mojo: `range()` is an iterable object.
Go: `for i := range n` only, no value.

**Alternatives.** (a) A range implementing `Iter[T]` itself, as §4.7's old
words said: `next()` mutates, so a range literal would need a `var` binding
to step, and a `Range` in a struct field would be a half-consumed iterator;
rejected: a range is a value (§4.7 "ordinary first-class values"), and the
iterator over it is its own state, as a List's is. (b) Keeping the bounds
hidden and building the iterator inside the compiler: the iterator would be
a fourth intrinsic family the day #2220 retires the others; rejected. (c)
`lower`/`upper` or `lo`/`hi` for the fields: `start`/`end` are the spec's
own words for the bounds (§4.7's `..` grammar) and Rust's.

**Prediction.** 85%: Eric takes it (the range iterates in a pipeline "as
`for` does" was his wording in D142; the fields are what the compiler
already knows, Law 1).

**Reopens if** ranges gain a step (`0..10 by 2`), which would make
`RangeIter` carry it, or a float range needs an iterator (`One + Ord` admits
`f64` today; stepping by one is what `..` means).
