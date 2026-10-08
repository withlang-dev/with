# D45 — A copy is never implicit unless it is O(1); an allocating copy is spelled

**Superseded for `str` by D111 (2026-10-08):** `str` is a value; a copy is a count increment and is never spelled.

**Laws:** 5, 1 (docs/mission.md).

**Date:** 2026-09-19. **Status:** ruled (Eric: "unless copy is O(1) we
should[n't] even consider doing it by default"; "yes for now option A … that
lands regardless of what happens to str later"). Specification §13.6's
examples do not yet conform (they build owning collections of `str` from
views without a clone); the wording is Eric's to bless. Measurement that
could reopen this: #1211.

**Question.** `let words: HashSet[str] = [w for w in tokens]` — `tokens` is
observed (D44), so `w` is a `&str`. Does the comprehension clone it? Mission
¶2 argues yes (the target type forces exactly one meaning). The same question
covers `let s: str = w` and passing a view to a consuming parameter.

**Ruling.** An owned-value demand on a view `&T` materializes a `T` only when
`T: Copy` (D22). For a type whose copy allocates, the programmer writes
`.clone()`. A comprehension's element, key and value positions are
owned-value demands like any other; they get no exception. A view of a Copy
type stored by a comprehension materializes (it stored `&i32` before); a view
of a Drop-class value is an error that says to clone it.

**Why.** Meaning is one gate; cost visibility is the other ("close to the
machine"). Verified in `.reference/`: of go, mojo, rust, scala3, swift, Vale
and zig, none copies a string implicitly while paying an allocation for it.
Every implicit-copy language made the copy O(1) first — Mojo (refcount, COW,
small strings inline), Swift (ARC retain, skipped for small and immortal
strings), Vale (`str` is always a shared type), Go and Scala (shared immutable
bytes). Rust, whose `String::clone` allocates, spells it. Mojo 0.25.6 drew
this exact line: `Copyable` became explicit (`.copy()`), `ImplicitlyCopyable`
opt-in; `List`, `Dict` and `Set` lost implicit copy because theirs allocates,
`String` kept it because its copy is a refcount bump. With's `str` is an owned
`(ptr, len)` buffer and §15.2 already marks `&str → str` as "(allocates)".
Cloning silently would have made With the only one of the eight that hides a
per-element allocation.

**Rejected.** Implicit clone in a typed comprehension only (a second rule for
one position, and the same hidden cost). A separate cheap string type in the
library (the default type, the one in every example, still needs the clone).

**What would reopen it.** `str` becoming O(1) to copy — immutable shared bytes,
a refcount in the allocation header, immortal literals (#1211 measures whether
that pays, including deleting the per-free `rt_payload_start_is_owned`
lookup). Then D22 extends by one line, and the string clones this ruling
requires become redundant and are removed. If the numbers are bad, this is the
permanent answer and §13.6's examples iterate `move tokens`.

**Supersedes nothing.** Extends D22 (owned-value demand) and D44 (traversal
observes) to the positions a comprehension stores from.

---
