# D186 — The iterator adapter is `skip(n)`; `drop(value)` stays the prelude's; `zip`, `chain` and `zip_with` take any iterable

**Laws:** 1, 9 (docs/mission.md).

**Date:** 2026-11-02. **Status:** `skip` ruled by Eric on the brief for
#2961; the iterable arguments delegated (D98) on #2962.

**Ruling (Eric's words).** "Rename the adapter to `skip(n)`. Two reasons
beyond the taste argument: `drop(value)` in the prelude is Rust's exact
meaning and With users who come from Rust will read `xs |> drop(3)` as a
destructor call; and `skip` is already what Rust and the iterator
vocabulary use, so it's a migration of zero and a new name of none.
`take/skip` is a pair readers already know from Rust and C#."

**Delegated beside it (#2962, 85%).** `zip`, `chain` and `zip_with` take
`impl IntoIter[U]`, as `for` and `await_all` do, so `xs |> zip(ys)` with
a `List` needs no `.iter()`. Law 1: the `.iter()` the table forced was a
spelling the compiler could insert.

**Implementation.** `drop(n)` is removed from the §13.3 table and the
prelude (no site in the tree uses it); `skip(n)` is the adapter;
`drop_while` becomes `skip_while` for the pair's sake. The three iterator
arguments widen to `impl IntoIter`. Fixtures for each.
