# D142 — A sequence on the left of `|>` iterates by the `for` rule; a slice has `iter()`; collecting views of values builds values

**Laws:** 1, 5 (docs/mission.md).

**Date:** 2026-10-21. **Status:** ruled by Eric. **Issue:** #2534 (surfaced
by the quicksort of 2026-10-21). Extends §13.5's implicit iteration to
pipelines; applies D111 and D139 to `collect`.

**Ruling (Eric's words).** A sequence on the left of `|>` iterating by the
same rule as `for` is right, and so is `iter()` on a slice. That's the same
traversal at a different altitude, as §13.5 says. Collecting views of value
elements builds a list of the values. That's D111's identity rule plus
D139: a view of a value carries nothing but the value, so a list of those
views should be a list of the values, not a list of borrows into `rest`.
Views of resources stay views, since those have identity.

**Why.** §13.5 already inserts `.iter()` for `for x in collection`, and
§13.5 calls literals, comprehensions and pipelines "the same machinery,
three altitudes"; the spec's own pipeline example pipes a `List`
(`text.split(pat) |> map(..) |> collect()`, §13.1). A pipeline whose left
side is a sequence has one meaning, so writing `.iter()` there is a
character the program had determined (Law 1). A slice is the view of a
sequence; its `iter()` yields the `&T` views a `ListIter` yields. Without
the collect rule the quicksort's `collect[List]()` over `rest`'s views
would build a `List[&isize]`, and the user would write `.map(*it)`: the
ceremony the ruling removes.

**What the others do.** Go ranges over slices directly; Rust's `[T]::iter`
exists on every slice and `for x in &v` iterates through `IntoIterator`;
Swift's `ArraySlice` is a full `Collection`; Scala 3's `pipe` applies to any
value and collections chain directly. No reference language makes the
programmer convert a sequence before chaining over it.

**Consequence.** Sema: when a pipeline's stage is no method of the value
but is one of the iterator its `.iter()` returns, the pipeline iterates
(`pipeline_implicit_iter`, the `for_iter_*` records keyed by the pipeline
node); MIR calls the inserted `.iter()` and the stage reads the iterator
wherever it read the piped expression. A slice's `iter()` is std's
`slice_iter` (`SliceIter[T]`, no `impl` can name a slice type), for the
spelled call, `for`, and `|>`. Collecting views of Copy values already built
values (`iter_collect_views`, #2271); a collection literal's elements with
no outer demand follow the same owned-demand rule, so `[pivot]` with
`pivot: &isize` is a `List[isize]`. Views of resources keep today's refusal
with the `map(it.clone())` hint. Fixture
`behav_d142_pipeline_over_sequence.w` is the quicksort as written.
