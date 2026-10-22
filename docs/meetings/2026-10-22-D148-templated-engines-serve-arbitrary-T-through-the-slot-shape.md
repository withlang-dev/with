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




## The brief (for veto or blessing)

Implemented and merged as PR #2562 (main 86fa6b794) under D98: not a C-interop, ownership or safety ruling in the sense the delegation excludes (the facade is the ownership boundary the plan's facade rules already fix; the engine's C is migrated With), easy to reverse (one corpus unit, six library modules), prediction above 75%. A veto is a revert.

### 1. What the others do

- **Rust**: generics are monomorphized; a container is written once in Rust and instantiated per `T` by the compiler. No templated C engine exists under `std`; where C libraries are wrapped (`-sys` crates), bindgen emits one binding per concrete instantiation and the Rust side is generic over an opaque handle plus `*mut c_void` plus a callback.
- **Zig**: `comptime` generics (`std.HashMap(K, V, Context, ...)`); a C template library would be instantiated by writing Zig code per shape. Zig's own containers are the model of "the shape set is declared where the facade is".
- **Swift**: generic over protocols with specialization; C generics do not exist, so Swift wraps C through opaque pointers and function pointers with a context (`UnsafeMutableRawPointer`).
- **Go**: generics since 1.18 by dictionaries/GC-shape stenciling; cgo wrappers are per concrete shape.
- **STC itself** answers "how does a C template serve many types": one `#define T name, key, val` + `#include` per type, i.e. the shape set is enumerated by the program. The facade does the same, once, in the corpus's build inputs.
- **The repo's own precedent**: the c-algorithms facades (`SortedList`, `BinaryHeap`, `Trie`) and the TommyDS `HashIndex` hand a `void*` engine pointers to facade-owned slots with the comparator at offset 0 (`std.collections.engine_slot`). D148 carries that pattern into a template engine: the template's hooks call a C-ABI function stored in the slot's head, which dispatches to the With comparator stored after it.

### 2. What the spec and the plan say

- **D37**: the migrator is raw — one concrete copy per instantiation the corpus contains, no lifting to generics in the migrator.
- **The 2026-09-12 facade map**: STC is the primary engine for `Deque`, `PriorityQueue`, `OrderedMap`/`OrderedSet`, `BitSet`, `sort` and the searches; "changing a primary engine requires a new ruling".
- **The plan, Phase 3**: the design item left open — (a) the facade declares a finite set of engine instantiations and routes each `T` to a shape, or (b) arbitrary `T` goes to a `void*` engine from another corpus; (b) is a comparison approach, not approval to replace STC. "Phase 3 must demonstrate how the selected STC engines support the generic facade contracts and record that design with benchmark evidence."
- **Facade rules**: the facade is the ownership boundary; one primary engine per abstraction, benchmarked against the comparison engines; a complexity fixture and drop-audit cells per facade; no `@[c_export]` or `with_*` externs in facades.
- **§2.3/D27/D22/D44**: no second live value from one; `get`/`peek`/`front` observe, `pop`/`remove` transfer, `insert` owns its inputs; traversal observes.

### 3. What landed

(a), with the slot shape as the arbitrary-`T` shape. One hand-written C unit in the corpus's build inputs (`facade_shapes.c`, build/stc.w → `std.engines.stc.facade_shapes`) instantiates `hset`, `sset`, `pqueue`, `deque` over pointers to facade-owned slots, a `deque` of words, `sort` over slot references and over i64/u64/f64, and `cbits`. `std.collections.stc_slot` defines the slot (`stc_slot_head` with two C-ABI callbacks, then the With comparator and hasher, then the value) and the two trampolines. Facades: `PriorityQueue`, `OrderedSet`, `OrderedMap`, `Deque` (`get(i)` until #2560), `BitSet`, `List.sort`/`sort_by`/`binary_search`/`lower_bound`/`upper_bound`/`reverse`. Each facade owns every value; fixtures, complexity rows (`test/complexity/stdlib.w`) and drop-audit cells per facade; `test/benchmark/stc_engines.w`.

Two general migrator rules were needed: a recursive `pub fn` keeps `-> Unit` (D143); a `static inline` function a header defines that no unit owns is published by its sole includer (several includers keep a private copy each, as before — `behav_migrate_header_inline_owner` refined). A unit named after a template header was tried and dropped: the header-owner rule then claimed every other includer's instantiations (the test corpus's `IDeq_at` went undefined).

### 4. The evidence

n = 100000 i32, ns per operation (insert/lookup/remove), median of 3, one compilation: PriorityQueue 18/0/109 against the c-algorithms BinaryHeap 17/0/111; OrderedSet 197/103/237 against the native BTreeSet 4371/481/4525 (n = 4000, #937) and the c-algorithms SortedList 6175/83/10435 (n = 20000); Deque 11/0/11 against List 2/0/1 (one slot allocation per element: the word shape is the next row when a Copy `T` needs it); `List.sort` 34 ns per i64 (word shape, in place), 200 ns per pair (references, one byte-move pass). All 8 STC upstream programs pass fresh and promoted; the drop audit's new facade cells are green; the `vec-into-iter` complexity row is a PASS (#938, fixed in the runtime: `remove(0)` advances the buffer's start, D115).

### 5. Mission fit

The shape set is declared once, next to the engine, and extended by adding a line to one C unit — never by editing migrated code or teaching the migrator about STC. The facade owns every value and every transfer is D27's; the engine sees pointers and bytes. STC stays the primary engine the ruling named, for arbitrary `T`, with the comparison engines measured beside it. Nothing the compiler could know is written by the user: `List.sort()` picks the word shape by `comptime if T.name()`.

### 6. Prediction

Eric blesses D148 as implemented (85%); the one likely amendment is the word-shape `Deque` row for Copy `T` (the plan's own "extend the shape set" move), and possibly a request that `std.algorithms`' binary search and bounds call the engine's instantiations rather than With's six lines (I kept them native: building a reference array to call an O(log n) search is O(n)).
