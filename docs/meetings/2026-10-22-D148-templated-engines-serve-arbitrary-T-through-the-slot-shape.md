# D148 — A templated engine serves an arbitrary `T` through the slot shape; the shape set is one C unit in the corpus's build inputs (delegated)

**Date:** 2026-10-22. **Status:** delegated (D98: not C interop in the
ruling's sense — the engine's C is migrated and the facade is the
ownership boundary as the plan's facade rules say — easy to reverse,
prediction ≥ 75%). Eric vetoes afterwards; a veto is a revert.

## The question

The stdlib sourcing plan (Phase 3) left one design item to settle with
evidence: STC's containers are define-then-include templates, the
migrator is raw (D37, one copy per instantiation), so a generic facade
over STC can be generic in one of two ways — (a) the facade declares a
finite set of engine instantiations and routes each `T` to a shape, or
(b) arbitrary `T` goes to a `void*` engine from another corpus. (b) was a
comparison approach, not approval to replace STC.

## The answer

(a), with the slot shape as the arbitrary-`T` shape. One hand-written C
unit staged beside upstream's (`facade_shapes.c`, build/stc.w, migrated to
`std.engines.stc.facade_shapes`) instantiates STC's templates once per
shape (a unit named after a template header would claim every other
includer's instantiations under the header-owner rule; the shapes unit
keeps its own name):

- the slot shape — `hset`, `sset`, `pqueue` and `deque` over
  `stc_slot_head*`: the engine indexes pointers to facade-owned slots whose
  head holds two C-ABI callbacks (`cmp`, `hash`) that dispatch to the With
  comparator and hasher stored right after the head
  (`std.collections.stc_slot`). This is the engine_slot pattern the
  c-algorithms facades already use, carried into a template engine: the
  template's `i_cmp`/`i_less`/`i_eq`/`i_hash` hooks call through the
  stored pointer, so one instantiation serves every `T`;
- the word shapes — `deque` of `uint64_t`, `sort` over `int64_t`,
  `uint64_t` and `double` with the engine's own `<`; `List[T].sort`
  selects them with `comptime if T.name() == "i64"` and so on;
- the slot reference — `sort` over `{cmp, ptr, with_cmp, with_env}`: a
  list of references ordered by the engine, then the elements laid out
  in that order by one pass of byte moves (every element moves exactly
  once, D27);
- `cbits`, which is not a template.

The shape set is extended in that one unit, never in migrated code. The
facades it feeds: `PriorityQueue`, `OrderedSet`, `OrderedMap`, `Deque`,
`BitSet`, `List.sort`/`sort_by`; `HashMap`/`HashSet` over `hset` wait on
the builtin engine swap (compiler intrinsics; a brief of its own).

## Why

- D37 holds: the migrator stays raw; the shape units are corpus build
  inputs, migrated like any unit. Two general migrator rules came out of
  it: a recursive `pub fn` keeps `-> Unit` (D143), and a `static inline`
  function a header defines that no unit owns is published by its sole
  includer (several includers keep a private copy each, as before). STC's
  template headers define their functions in other headers (`hset.h` is
  `hmap.h`, `sort.h` is `priv/sort_prv.h`), so the header-owner rule alone
  could not reach them; the sole-includer rule is the general statement of
  "one definition, one owner".
- The facade is the ownership boundary (plan, "Facade rules"): the engine
  sees pointers and bytes; views, transfers and drops are the facade's.
- STC stays the primary engine for arbitrary `T`, as ruled 2026-09-12; the
  comparison engines (c-algorithms heap and sorted array, the native
  BTreeSet) are measured beside it (`test/benchmark/stc_engines.w`).

## What would reopen it

A measured case where the slot indirection costs more than a direct
instantiation would save and matters (then that `T` gets a word-shape
row in the unit, which is the design working as intended); the builtin
`HashMap`/`HashSet` swap, which is its own brief.



