# D33 — Consuming iteration: §13's `into_iter()` reaffirmed as the surface; observe-by-default stands; the iterator owns the tail

**Date:** 2026-08-31
**Status:** Ruled by Eric on the #724 brief. Satisfies D23's deferral
("#724 needs its own design ruling") — the ruling is that §13 (normative
since 2026-02-24) and D27 already compose the answer, so the spec text
stands unchanged. Supersedes nothing; #712's borrow-default iteration is
reaffirmed alongside it.

**Ruling (verbatim):**

> §13 reaffirmed as the ruling — into_iter() is the consuming surface;
> D23's deferral is satisfied by the D27 composition. Campaign per §5
> approved. B deferred as possible future sugar over A, not a competing
> surface. Trait rename: bring me the naming pair before it lands. Add
> a moved-iterator fixture to acceptance.

Where: "§5" is the brief's implementation campaign (below); "A" is
`into_iter()` as spec'd; "B" is a hypothetical `for x in move xs:`
keyword spelling — deferred as possible future *sugar over*
`into_iter()`, never a competing mechanism.

**The rule.** D27 composed at loop granularity: access observes,
transfer is explicit. `for x in collection:` borrows — always, per
#712; the collection outlives the loop. `collection.into_iter()` is the
explicit whole-collection transfer — a `move fn` that consumes the
collection and returns an iterator that *owns* it, yielding elements by
move. Early exit (`break`, `?`, return) drops the iterator; its drop
releases the un-yielded tail and the buffer exactly once — ordinary
Higher RAII, no special loop semantics.

**Context.** #724: `await_all` owns its collection but #712 routed all
iteration through borrow dispatch, so `pending.push(task)` bit-copied
Tasks through views — two owners, invalid free at runtime (ss14_11 ×2
pinned as evidence). Pre-#712 owned iteration consumed soundly; #712
rightly retired it for borrows and owned-element transfer went with it.
The gap: no way at all for an owned collection to yield elements by
move. Meanwhile spec §13 had normatively listed
`for item in my_vec.into_iter():   // consuming (moves elements)` since
2026-02-24 while D23 called the design open — this ruling resolves that
collision by reaffirming the spec text.

**Alternatives weighed.** Keyword-only `for x in move xs:` — reads
with-y post-D32, but needs new for-loop lowering, yields no iterator
value for combinators, and would require respelling §13 anyway;
deferred as future sugar. No-consuming-iteration (concrete
`remove`-loop / `Vec`-typed APIs only) — taxes every owned-collection
user with clone-or-drain ceremony and forces async combinators onto
concrete types; rejected.

**Campaign (approved).** `VecIntoIter[T]` (owning, non-ephemeral) +
`move fn into_iter()` on `Vec` + `Iter` impl; the existing borrow-only
`IntoIter[T]` trait is misnamed (it is Rust's `&Vec` impl wearing the
owned impl's name) — rename it and introduce a genuine consuming trait,
**naming pair goes to Eric before it lands**; `await_all`/`await_first`
respelled onto consuming iteration (the double-own dies structurally);
ss14_11 pins removed as acceptance; `--debug-alloc` fixtures for
full-consume, break-early tail drop, error-path drop, and — per the
ruling — a **moved-iterator** fixture (the iterator value itself moved,
then driven; drop-exactly-once).

**Naming ruling (2026-08-31, Eric: "I bless A").** The pair: a trait is
named by the method it promises. **`IntoIter[T]`** = consuming
(`move fn into_iter() -> VecIntoIter[T]`); **`Iterable[T]`** = borrowing
(`fn iter(self: &Self) -> VecIter[T]`, the former misnamed `IntoIter`).
Internally consistent with the -ator-less house scheme: trait `Iter` /
type `VecIter` :: trait `IntoIter` / type `VecIntoIter`. Alternatives
declined: `IntoIterable`/`Iterable` (name drifts from its own method),
`AsIter` (Rust-ese, not English).

---
