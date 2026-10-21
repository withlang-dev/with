# D141 — An inferred return type joins `None` with `T` into `Option[T]`

**Laws:** 1, 2 (docs/mission.md).

**Date:** 2026-10-21. **Status:** ruled by Eric ("blessed"). **Issue:** #2220
(step 2 review of `ListIter.next`). Amends D43; carves a case out of D103.

**Ruling (Eric's words).** Where a return type is inferred, branches of
type `T` and `None` join to `Option[T]`. A branch already of type
`Option[T]` beside `None` does not join, since `Option[Option[T]]` would be
a second meaning, and the type must be written. The conversion still never
solves a type variable.

**Why.** D43 rules that an unannotated return infers only when every
written arm unifies, and that a mixed join is a failure to infer. D103
rules that the value-to-Option conversion "never participates in
inference": that clause keeps the conversion from solving type variables,
which stays right. Inferring a return type from its branches is a form of
inference, so as written D103 forbade this join; the ruling carves the
case out explicitly rather than let the implementation decide what D103
meant. `None` beside a `T` has one meaning under D103's "once" (a `T`
never becomes `Option[Option[T]]`); `None` beside an `Option[T]` has two,
so it is written.

**Searched before ruling.** `docs/meetings`: D43 is the only ruling on
inferred returns; D114's record has no literal-tail note (the `isize`
default is the untyped-literal rule, D124/D128 refine it as literal
typing, not return inference).

**Consequence.** `ListIter.next` reads

```
mut fn next():
    if self.idx >= self.list.len(): return None
    let i = self.idx
    self.idx += 1
    &self.list[i]
```

**What would reopen it.** A join of `None` with a `T` whose `Option[T]`
the caller never wanted (the body meant a sentinel); no such case is
known, and the annotation remains available.
