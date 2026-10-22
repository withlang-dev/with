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
`pivot: &isize` is a `List[isize]`. Fixture
`behav_d142_pipeline_over_sequence.w` is the quicksort as written.

**Amendment (Eric, 2026-10-22: "fix it").** The first implementation kept a
refusal for views of resources ("cannot copy them out, `map(it.clone())`").
The ruling's letter is that they stay views, so collecting them builds a
list of views: an ephemeral `List[&T]`, as §22.1 rules 3 and 7 already
describe (the container holding a view is ephemeral; returned, the caller's
binding is; a struct field or a global of one stays refused). A local
`List[&T]` is no longer refused at its `let`; `var vs = []` fed a resource
view is a `List[&T]` (a Copy view still demands the value, D139); `collect`
over resource views is plain `iter_collect` with `T = &T`; the escape
checks are the ones every ephemeral value has (`returned ephemeral value
may outlive its origin`). §3.3's bullet "elements of heap containers" is
the one sentence that still says otherwise; its amendment is Eric's.
Fixtures `behav_d142_resource_views_collect.w`,
`err_d142_resource_views_escape.w`.
