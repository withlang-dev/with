# D152 — A collection's copy class is part of its interface: `List`, `HashMap` and `HashSet` copy with a count; every engine-backed collection is a resource, by D45

**Date:** 2026-10-23. **Status:** ruled (Eric). **Laws:** 5, 1
(docs/mission.md). Extends D120; the line is D45's. Reopened by nothing
short of a ruling: changing a type's class is an interface break.

## The fact that forced the question

`test/behavior/behav_d120_struct_value_copy.w` pinned that `var n = m` on
a `BTreeMap` copies. Under D120 the old `BTreeMap` was a struct over a
`List`, so the copy was a counted copy-on-write one. Over the M*LIB B+tree
(D151) the map holds the engine's root and has a `Drop`; `var n = m`
moves it. The brief (`docs/meetings/2026-10-22-D151-…`'s companion) offered
A, resource with `.clone()`, and B, copy-on-write with the compiler
inserting make-unique before every `mut fn` on the facade.

## The ruling (Eric, 2026-10-23)

A. "B is the compiler knowing a facade's layout, which D151 just removed,
and it hides an O(n) clone behind `=`." But the fixture is the real
finding: "BTreeMap-as-struct was an implementation fact" is the §4.10
pattern again, a documented default that a fixture elevated into
semantics, which then broke when the representation changed. Three things
so it does not recur:

1. **A collection's copy class is part of its interface, stated in std,
   not a consequence of its layout.** D120 names the types it covers:
   `List`, `HashMap`, `HashSet` copy with a count; every engine-backed
   collection (`BTreeMap`, `BTreeSet`, and all of D148's: `OrderedMap`,
   `OrderedSet`, `PriorityQueue`, `Deque`, `UnorderedMap`, `UnorderedSet`,
   `BitSet`) is a resource. Changing a type from one class to the other is
   an interface break and gets its own ruling, so a facade rewrite can
   never silently flip it.

2. **The fixture line is a migration, and it changes meaning.** `var n =
   m.clone()` is the same observable result but a different cost, and a
   breaking change for every program with a `BTreeMap` today. The release
   notes say so (the runbook's checklist carries it), and the moved-value
   diagnostic on a collection suggests `.clone()` with its cost, since
   this is the first thing anyone upgrading hits.

3. **The asymmetry is justified, or users will see it as arbitrary.** Why
   does `var n = list` copy but `var n = btree` move? A `List` or hash
   table is a value whose copy is a bounded, flat memcpy-and-count; a
   B-tree is a graph of nodes that cannot be copied without walking it.
   That is the line D45 drew (implicit copy only when O(1)); the
   count-copy is O(1) and the tree copy is not. `BTreeMap` is a resource
   because of D45, not because of M*LIB.

**Decided with it.** D120's copy-on-write for `HashMap` was stage 2. If
`HashMap` moves to an engine under a later brief (STC as the comparison
engine, say), it keeps its value class under this rule, so its engine
facade must support the count-copy. That constrains the hash engine choice
from Brief 1, and is decided now.

## What changed

Specification §2.3 names the classes; `behav_d120_struct_value_copy.w`'s
one `BTreeMap` line reads `var n = m.clone()` under the ruling; Sema's
moved-value diagnostic on an engine-backed collection names the class and
the clone's cost; the release runbook's notes checklist carries the
breaking change.
