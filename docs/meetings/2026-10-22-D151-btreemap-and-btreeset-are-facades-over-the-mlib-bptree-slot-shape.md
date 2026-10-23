# D151 — `BTreeMap` and `BTreeSet` are facades over the M*LIB B+tree slot shape; the compiler no longer knows their layout (delegated)

**Date:** 2026-10-22. **Status:** delegated (D98): a facade over a ruled
engine (the plan's Phase 4), reversible by re-promotion; Eric vetoes
afterwards.

## The decision

`std.collections.BTreeMap[K, V]` and `BTreeSet[T]` are facades over
`std.engines.mlib.facade_shapes` (M*LIB's `m-bptree.h`, D146's corpus
`mlib`), instantiated once as a B+tree of rank 16 over slot pointers
(`mlib_slot_tree`, the D148 slot shape): each entry is one facade-owned slot
holding the With key (and the map's value) after a head that carries the
C-ABI comparison, which dispatches to the facade's `Ord` comparator
(`std.collections.mlib_slot`). The surface is unchanged (`new`, `len`,
`is_empty`, `clear`, `get`, `insert`, `remove`, `contains`, `first`, `last`,
`iter`/`keys`/`values`, the consuming traversals, `:?`; the set's `items`,
`union`, `intersection`, `difference`), and the sorted-List implementation
(#937: O(n) lookups, O(n²) fills) is gone.

With it, the compiler's knowledge of the two types' representation is
retired (D65: one owner per fact). A `for` over a `BTreeMap` is the facade's
`iter()` through the general §13.5 rule, as any type's is (Sema's
`btree_traversal_element_type` and MIR's `lower_for_btreemap` are deleted);
a literal or comprehension that fills one starts from the facade's own
`new()`, which Sema specializes for the concrete type and records
(`record_btree_new_contract`) so MIR calls it instead of building the
struct's fields (`btree_storage_list_type`, `emit_btree_new_into`'s
aggregate, `lower_btree_new`). `insert` kept its recorded contract.

## Why

D148 settled how an arbitrary `T` rides a templated C engine; the plan fixed
Phase 4 to the B+tree and these two facades. The compiler special cases
existed only because the old types were structs over a `List`; with the
layout an engine's, every one of them would have had to be rewritten to
know the engine, which is the boundary smell the mission names (deleting a
downstream heuristic must never change which programs are accepted). The
general paths were already there for every other collection.

## Evidence

- `test/behavior/behav_btree_engine.w` (order, replace, transfer, first/last,
  traversal, literals and comprehensions, set algebra, `:?`, exactly-once
  drops); the existing `behav_btreemap_for_traversal.w` and the other 13
  BTree fixtures unchanged.
- `test/complexity/stdlib.w`: `btree-map-ascending`, `btree-map-descending`,
  `btree-set-ascending`, `btree-set-descending` PASS (XFAIL #937 before).
- `tools/drop_audit.w`: `btree_map_{empty,full,partial,replace,cursor,literal}`,
  `btree_set_{empty,full,partial,replace,cursor}` cells.
- `test/benchmark/stc_engines.w`: BTreeSet/BTreeMap rows beside OrderedSet
  (STC sset), SortedList and the native rows; numbers in the plan.
- The corpus: `build/mlib.w`, `lib/std/engines/mlib`, upstream's multimap
  example as the drift harness and `mlib-test` lane.

## What the engine's shape settled on the way

- **Separators own key clones.** A B+tree copies keys into its internal nodes
  as separators. With pointer keys and a pointer-copying `INIT_SET`, a
  separator kept pointing at a slot the facade freed on `remove`, and the
  comparator read freed memory (M*LIB's own contract assertion fired in a
  native C probe of the shape). So the slot oplist owns its copies:
  `INIT_SET` clones the slot through a With callback (the key cloned),
  `CLEAR` drops it, and every slot the engine holds points back at the
  facade's entry. Hence `BTreeMap[K: Ord + Clone, V]` and
  `BTreeSet[T: Ord + Clone]`: a key is cloned into the index an
  implementation-defined number of times, as M*LIB's `string_t` keys are.
  A key with an observable `Drop` must treat a clone as identity-free (the
  fixture's and the drop audit's record types do).
- **A map is a resource.** The engine's tree is owned memory with a `Drop`;
  `var n = m` moves and a copy is `m.clone()` (O(n)), as every D148 facade.
  The D120 fixture copied a `BTreeMap` by assignment under the old
  List-backed struct; that line is the one open question for Eric (brief in
  the session notes): resource with `.clone()` (predicted), or copy-on-write
  that the compiler would have to know the layout for again.
- **The compiler's `extern fn` view.** The corpus's own `strlen` is `size_t`;
  promoted corpora carry an older `i64` declaration. An `extern fn` is now
  its module's view of a C symbol (`Sema.extern_view_sig`), the frontend
  never drops a lower tier's extern for a higher tier's same-named one, and
  an interface's declaration keeps its own signature beside a source
  owner's; `test/behavior/behav_extern_module_views.w`. This is what lets a
  new corpus coexist with every promoted one (D112's enforcement note).
