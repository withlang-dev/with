# D149 — The hash family's engine is rt_core's insertion-ordered layout; STC `hmap`/`hset` is the comparison engine and backs an unordered map under its own name (amends the 2026-09-12 facade map)

**Date:** 2026-10-22. **Status:** ruled by Eric on the brief at #2563.

## The ruling

> Rule A now, don't rule B yet.
>
> The prediction reads B as the natural end state, but B isn't what D96
> means. D96 says rt_core implements Python's layout, and that layout is
> dense entries plus an index. In a compact dict the index is the thin
> part: it maps a hash to an entry number, and all the real work (the
> dense array, order, deletion tombstones, compaction) lives in the
> entries. Putting STC hmap under that index buys almost nothing — the 36
> ns the benchmark shows is for a map where keys and values sit inline in
> STC's slots, which is exactly what B gives up. B would import a corpus
> dependency into the runtime, invert the D30 build direction, and leave
> the hot path where it was. The brief's own §3 says the gain is "a
> constant-factor gain, not a complexity class," and B doesn't even keep
> the constant.
>
> So the real choice is narrower than four options: either insertion
> order stays (D96) and rt_core's layout is the engine, or it goes. C is
> refused, and that settles it. A amends the facade map to say STC
> hmap/hset is the comparison engine, not the primary. That's an honest
> correction to the 09-12 map, which was written before D96 was ruled.
> The one thing to add: an unordered HashMap is a real request for hot
> paths that don't need order, and the STC slot facade can be that, under
> a separate name, the way Zig ships both. That's where the 36 ns goes.
>
> If you still want B, measure it first — rt_core's index swapped for
> STC's, with inline entries left in place — before committing to the D30
> inversion. I expect the number to be close to today's 79.

## What this fixes

- `HashMap[K, V]` and `HashSet[T]` keep rt_core's engine: Python's compact
  layout (dense entries in insertion order, an index of entry numbers),
  seeded, D96's order. The 2026-09-12 facade map's rows for the hash
  family now read: primary engine rt_core's layout; comparison engine STC
  `hmap`/`hset` (beside TommyDS and c-algorithms), measured in
  `test/benchmark/hash_engines.w`.
- An unordered map and set, for hot paths that do not need order, are a
  facade over the STC slot-shape `hset` under their own names
  (`UnorderedMap[K, V]`, `UnorderedSet[T]` in `std.collections`), the way
  Zig ships `HashMap` beside `ArrayHashMap`. Their contract is D22/D27/D44's
  (`get` observes, `insert` owns and returns the replaced value, `remove`
  transfers, traversal observes) in no stated order.
- Option B (STC's index under rt_core's entries) is not ruled; it is
  measured first if ever wanted: rt_core's index swapped for STC's with the
  inline entries left in place, before any D30 inversion.

## The measurement the ruling read

i32 keys, n = 200000, ns per operation (insert/lookup/remove), median of
3, one compilation: rt_core `HashMap` 79/28/33; STC `hset` through the slot
shape 43/17/45.
