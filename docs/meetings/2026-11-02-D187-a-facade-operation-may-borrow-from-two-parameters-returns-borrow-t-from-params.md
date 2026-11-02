# D187 — A facade operation may return a borrow from two parameters: `returns borrow T from params N, M`, invalidated when either is

**Laws:** 4, 9 (docs/mission.md); D51, D134.

**Date:** 2026-11-02. **Status:** ruled by Eric on the brief for #2965,
against the prediction (which left the operation raw until needed).

**Ruling (Eric's words).** "It's sound (Law 4), the clause is one line,
and the reason already exists. The first facade that hits it is libxml2's
`xmlAddChild(parent, cur)`, which is in the UAT, and inference (c) from
the migrator work already produces 'a returned pointer derived from a
parameter' for migrated engines. Within a compilation unit the body says
which parameters a return derives from; a union of two is the natural
result of that analysis, and refusing it means the migrator emits
`unsafe fn` for exactly the functions a reader would most expect to be
safe. So: write the clause now, `returns borrow T from params 0, 1`,
meaning the view is invalidated when either is, and apply it where either
a facade states it or the migrator's proof produces it. What stays
unruled is a union origin across a *bundle boundary* without a
declaration, which is §3.4's existing rule, unchanged."

**What it means.** `returns borrow T from params N, M` on an fn item
states that the returned view borrows from both named parameters' origins
at each call: it lives no longer than the shorter, is invalidated when
either origin's views are, and cannot be stored beyond either. A facade
may state it; the migrator applies it where its proof shows a returned
pointer derived from two parameters, instead of emitting `unsafe fn`.
Across a bundle boundary a union origin still needs the declaration
(§3.4).

**Implementation.** The facade grammar (§30) admits `params N, M`; Sema's
origin binding records a set per call and invalidation checks every
member; the migrator's derived-pointer proof emits the clause; the
libxml2 UAT's `xmlAddChild` is the first fixture.
