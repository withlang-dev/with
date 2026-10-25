# Stdlib sourcing: three migrated corpora, one facade

Status: PLAN (2026-09-01), engine selections ruled 2026-09-12; **all four
phases implemented** (2026-10-23). The facade map's unfilled rows are listed
under "What remains" at the end.

**Implementation status (2026-10-24, main `a768dd65e`).** Phase 0 landed
(#1129: complexity lane, SlotMap free list). Phase 1 c-algorithms landed
2026-09-14 (#1142: third `.wo` bundle, 17 upstream tests, `Trie[V]`,
`SortedList[T]` (this plan's `SortedVec`), `BinaryHeap[T]`, `engine_slot`).
Phase 2 TommyDS landed in the same merge (fourth bundle, `check.c` green,
`HashIndex[K, V]` over `hashdyn`, the hash-engine benchmark below). Phase 3
STC landed 2026-10-22 (D146–D150: the fifth bundle including `stc_core`
after D147 bitfields, 8 of 8 ctest units, the slot and word shapes,
`PriorityQueue`, `OrderedMap`/`OrderedSet`, `Deque`, `BitSet`,
`UnorderedMap`/`UnorderedSet`, and `std.algorithms` giving `List` `sort`,
`sort_by`, `binary_search`, `lower_bound`, `upper_bound`, `reverse`). Phase 4
M\*LIB landed 2026-10-22/23 (D151: `BTreeMap`/`BTreeSet` over the B+tree, slot
and word shapes, `test-mbptree.c` green). #937, #938, #939 and #940 are
closed. D155/D156 (2026-10-23/24) fixed every corpus's data model so the five
bundles compile on each seed platform, and the joint seed
`nightly-20261024-local-4-0cca9aee2744` carries them.
`docs/spec/stdlib/libstd-spec.md` maps its tiers onto these phases (its
Phase 3 "pending" rows predate 2026-10-22 and are refreshed separately).
Module grouping follows D146: engines under `std.engines.<library>`, facades
named for their function under `std.collections` and `std.algorithms`.
Companion: `docs/proposals/harden_migrate.md` (the migrator plan this
campaign exercises), `docs/proposals/harden_plan.md` item 7.

## The ruling

Miguel's SlotMap finding (#936) prompted a survey of every core container's
actual algorithm (#937 BTreeMap/BTreeSet are sorted Vecs with linear lookup
and an O(n²) insert; #938 consuming iteration is O(n²); #939 HashMap delete
allocates per displaced entry; #940 there is no sort at all). The finding
underneath: the containers were written to pass their fixtures, and nothing
ever measured complexity.

The answer is not a native rewrite and not a C wrapper. It is With's own
first-class path:

> Migrate the library **whole** with `with migrate`, preserve it as a
> coherent upstream-derived corpus, then **selectively facade** only the
> parts With wants to expose. We never migrate pieces; we facade pieces.

And the division of labor (Eric, same day; decisions.md D37):

> `with migrate` is **raw**. The With-ness resides in the facade.

The migrator's output is a faithful, C-shaped With transpile of the corpus
— raw pointers, `void*`-and-`elem_size` genericity, comparator callbacks,
one concrete copy per template instantiation the corpus actually contains.
It adds no ownership modeling, no generic lifting, no ergonomics. Every
With-ism (views, transfers, drops, `Deque[T]`, `Vec.sort`) is the facade's.

Three corpora with complementary roles, plus one surgical port:

| Corpus | Role | Verified at upstream |
|---|---|---|
| **c-algorithms** (fragglet) | classic, readable reference implementations: RB/AVL trees, binary heap, sorted array, trie, hash table, list, queue | ISC; autotools; one `.c`/`.h` pair per module; `test/` suite |
| **TommyDS** (amadvance) | hardened performance hashing/indexing: `hashtable`, `hashdyn`, `hashlin`, `trie`, `trie_inplace`, `array`, `arrayblk`, `list` | Makefile; `check.c` test program; `benchmark/` |
| **STC** (stclib) | modern breadth: `vec`, `deque`, `stack`, `queue`, `pqueue`, `list`, `hmap`/`hset`, `smap`/`sset`, `cstr`, `cbits`, spans, and a generic algorithm layer (sort, binary search, shuffle, reverse, …) | MIT; C99/C11; define-then-include templates (`#define T MyVec, int` + `#include <stc/vec.h>`); `tests/`; Meson + Makefile; v6.0 RC4 |
| **M*LIB** (P-p-H-d) — surgical | `m-bptree.h` only: the B+ tree machinery STC does not obviously fill | BSD-2; macro-instantiated; `tests/` |

Outside the corpora, written natively: graph algorithms and union-find
(too small for migration provenance to beat a native version), SlotMap's
free list (#936 — no mature C library ships generational slot maps).
`Vec` moves to STC's engine while preserving its language integration;
STC's `cstr` is used selectively without changing With's `str` contract.

**The sourcing rule** (Eric, 2026-09-02). Why we take code from these
libraries at all: **hardenedness**. ffmpeg, zlib, minicoro, pcre2 have
stood the test of time; decades of production use found the bugs a fresh
implementation would have to find again. Upstream test suites and
release tracking are how we keep that hardenedness, not the reason for
it. Given that, the split is about the code's shape, not its value:
migrate-and-facade for *libraries* — pcre2, zlib, the container corpora —
where the migrator can carry the hardened code across faithfully;
hand-port and own for *runtime and low-level primitives* that are small,
stable, and entangled with assembly or the allocator, where a port is the
faithful form: the fiber switch (minicoro is the hardened reference to
port from; `runtime/fiber_asm_*.s` already exists), the crypto primitives
(`lib/std/crypto`, 2.5k lines in BearSSL's image against 59k of upstream,
of which we use only the primitives — held to upstream's known-answer
vectors as fixtures), and the allocator.

To confirm at pin time, not from memory: TommyDS's exact license text (its
`COPYING`), and that c-algorithms is `void*` + comparator callbacks
throughout (expected; it determines facade shape).

## Facade and engine selection — Eric's ruling (2026-09-12)

For With’s default `HashMap[K, V]` / `HashSet[T]` engine, we will use
STC’s `hmap` / `hset`.

STC’s current hash map uses Robin Hood hashing, stores keys/values directly
in the table, and keeps a compact side table of hash/bucket metadata. That
shape maps naturally onto the facade With wants: an owning generic
`HashMap[K, V]`, rather than a C-style intrusive index over separately
allocated objects.

The facade map is explicit. The corpora are implementation engines; their
names do not automatically become permanent standard-library API names
(D146: facades are named for their function, engines for their provenance,
and neither maps onto the other). This ruling supersedes the earlier open
engine choices in this plan. Benchmarks validate the selected engines and
compare alternatives; changing a primary engine requires a new ruling.
**D149 (2026-10-22) amended the hash family**: `HashMap`/`HashSet` keep
rt_core's insertion-ordered layout (D96 was ruled after this map); STC
`hmap`/`hset` is their comparison engine and backs
`UnorderedMap`/`UnorderedSet` under their own names. **D148** settled how a
templated engine serves an arbitrary `T`: the slot shape (one C unit in the
corpus's build inputs instantiates the templates over pointers to
facade-owned slots) plus a word shape for integer scalars where measured.
**D152**: `List`, `HashMap` and `HashSet` are values that copy with a count;
every engine-backed facade is a resource (D45).

Names: With's growable contiguous sequence is `List[T]` (the `Vec` of this
map; there is no `Vec` in `lib/std`), and the sorted array is
`SortedList[T]`. The **Status** column records the tree as of 2026-10-24.

| `lib/std` facade | Primary engine | Secondary / comparison engine | Status |
| --- | --- | --- | --- |
| `List[T]` (this map's `Vec`) | **rt_core** (D157: the compiler's knowledge of the layout is the engine) | STC `vec` (the benchmark's comparison row), TommyDS `array` | Ruled 2026-10-24; its algorithms are STC's (below) |
| `Deque[T]` | **STC `deque`** | — | Done (D148: slot shape, word shape for integer scalars); `d[i]` is the element view through `IndexGet` (#2560 fixed 2026-10-24) |
| `Stack[T]` | **STC `stack`** | — | Done 2026-10-24 (`std.collections.stack`; slot and word shapes) |
| `Queue[T]` | **STC `queue`** | c-algorithms queue | Done 2026-10-24 (`std.collections.queue`; slot and word shapes) |
| `PriorityQueue[T]` | **STC `pqueue`** | c-algorithms binary heap | Done; the max-queue of a signed word takes the word shape (2026-10-24) |
| `LinkedList[T]` | **STC `list`** | c-algorithms list / TommyDS list | Done 2026-10-24 (`std.collections.linked_list`: both ends push, the front pops, reverse, sort; slot and word shapes) |
| `HashMap[K, V]` | **rt_core's insertion-ordered layout** (D96, D149) | STC `hmap`; TommyDS `hashdyn` / `hashlin`; c-algorithms hash table | Done as ruled; #939 closed |
| `HashSet[T]` | **rt_core's insertion-ordered layout** (D96, D149) | STC `hset`; TommyDS hashing machinery | Done as ruled |
| `UnorderedMap[K, V]` / `UnorderedSet[T]` | **STC `hmap` / `hset`** (the slot shape, D148) | — | Done (D149); an integer `UnorderedSet` key is the engine's own word (2026-10-24) |
| `OrderedMap[K, V]` | **STC `smap`** | c-algorithms RB tree / AVL tree | Done |
| `OrderedSet[T]` | **STC `sset`** | c-algorithms RB tree / AVL tree | Done |
| `BTreeMap[K, V]` | **M*LIB `m-bptree`** | — | Done (D151; slot and word shapes); #937 closed |
| `BTreeSet[T]` | **M*LIB `m-bptree`** | — | Done (D151) |
| `Trie[V]` | **c-algorithms trie** | TommyDS `trie` / `trie_inplace` | Done |
| `BitSet` | **STC `cbits`** | — | Done |
| `Span[T]` | Dropped (D158): strided and multi-dimensional views are the language's (§4.8a slices, D119 arrays, the multi-dimensional indexing goal) | STC `cspan` stays a migrated engine | Ruled 2026-10-24 |
| `String` / internal string engine | **STC `cstr` where useful** | Existing With string implementation | Not done; `str` stays the contract (D111) |
| `SortedList[T]` (this map's `SortedVec`) | **c-algorithms sorted array** | STC algorithms + `List` | Done |
| `ChunkedVec[T]` / internal block storage | **TommyDS `arrayblk`** | — | Migrated, no facade (internal engine) |
| `Index[T]` / intrusive object index | **TommyDS `hashtable` / `hashdyn`** | — | `HashIndex[K, V]` over `hashdyn` done; `hashtable` internal |
| `IncrementalHashIndex[T]` | **TommyDS `hashlin`** | — | Migrated, no facade (internal engine) |
| `BinaryHeap[T]` | **c-algorithms binary heap** | STC `pqueue` | Done (public) |
| `RbTree[K, V]` | **c-algorithms RB tree** | — | Migrated, internal comparison engine |
| `AvlTree[K, V]` | **c-algorithms AVL tree** | — | Migrated, internal comparison engine |
| `sort` / `sort_by` | **STC algorithm layer** | — | Done on `List` (#940 closed) |
| `stable_sort` / `stable_sort_by` | Evaluated separately (2026-10-24): STC's sort is a quicksort with no stability contract, so the stable sort is a merge sort over the same reference layout, owned | — | Done on `List` |
| `binary_search` | **STC algorithms** | c-algorithms sorted-array logic | Done on `List` |
| `lower_bound` / `upper_bound` | **STC algorithms** | c-algorithms | Done on `List` |
| `reverse` | **STC algorithms** | — | Done on `List` |
| `shuffle` | Fisher–Yates through std.random (STC's `c_shuffle_array` is a macro over its own generator) | — | Done on `List` (2026-10-24) |
| `find` / search helpers | The language's iterator adapters (`find`, `position`, `index_of`, `contains`) | — | Not a facade row: already the language's |
| Heap algorithms | **STC `pqueue` / c-algorithms heap** | — | Behind `PriorityQueue`/`BinaryHeap`; no generic heap utilities |

The public surface is grouped as follows (D146):

- `std.collections`: `List`, `HashMap`, `HashSet`, `BTreeMap`, `BTreeSet`,
  `SlotMap` in `lib/std/collections.w`; `Deque`, `Stack`, `Queue`,
  `LinkedList`, `PriorityQueue`, `OrderedMap`, `OrderedSet`, `UnorderedMap`,
  `UnorderedSet`, `BitSet`, `Trie`, `SortedList`, `BinaryHeap`, `HashIndex`
  as `std.collections.<name>` under `lib/std/collections/`, with the slot
  machinery `engine_slot`, `stc_slot` (the slot and entry lifetimes, written
  once: `stc_slot_new`/`view`/`take`/`release`, the probe, `StcEntry`),
  `stc_word` (the word shape's conversions) and `mlib_slot`.
- `std.algorithms`: `List.sort`, `sort_by`, `stable_sort`, `stable_sort_by`,
  `binary_search`, `lower_bound`, `upper_bound`, `reverse`, `shuffle`
  (`lib/std/algorithms.w`).
- There is no `std.slice`/`std.span` (D158): `[]T` and D119's arrays are
  the views, and multi-dimensional slicing is a language feature.

Several imported structures remain engines rather than public types.
TommyDS `hashdyn`, `hashlin`, `arrayblk`, c-algorithms’ AVL/RB trees,
and perhaps the raw M*LIB B+ tree can sit underneath the public facade
without forcing their implementation names into the permanent API.
Optional exposure in the table remains optional.

**STC provides most everyday containers and algorithms; c-algorithms
supplies the classical trees/heaps/trie and reference implementations;
TommyDS supplies specialized high-performance indexing/storage engines;
M*LIB supplies the B+ tree.**

## Why the un-facaded code is not waste

Everything migrated compiles in the battery whether or not a facade uses
it. That gives:

- migration regression coverage on real generic C, forever;
- alternative engines under identical With compilation, so benchmarks
  validate the selected primary engines and quantify tradeoffs (several
  migrated hash tables underneath, exactly one default facade);
- examples for future facade expansion;
- a standing corpus for finding migrator bugs;
- internal assumptions kept intact — no partial fork where `sort.h` came
  over but the shared template machinery it evolved with did not.

## The pipeline (pcre2's, reused)

Per corpus (since 2026-09-14 the generic pipeline in `build/corpora.w`
driven by the registry, `docs/spec/toolchain/wo_bundles.md` "The corpus registry"; a
corpus is a `Corpus` declaration in `build/<corpus>.w` plus its hooks):

1. **Pin.** Upstream release tag, tarball URL, sha256 constant. Re-migration
   happens only when the pin changes (the SDLC rule: we re-migrate, never
   edit generated code).
2. **Reference target** (`<corpus>-reference`): fetch and verify the
   archive, unpack under `out/`, network allowed only here.
3. **Migrate target** (`<corpus>-migrate`): `with migrate` the whole tree
   through a workspace, reject any `@[c_export]` in the output, require a
   file-count floor, publish atomically into the generated directory.
4. **Upstream tests** (`<corpus>-test`): migrate the library's own test
   programs too and run them under With. That is the correctness oracle;
   the facade's fixtures are the ergonomics oracle.
5. **Migrator failures are migrator bugs.** A construct the migrator cannot
   lower fails loudly (§No Silent Fallbacks) and is fixed in `with migrate`
   as a general rule — never a corpus-specific special case (the standard
   set in the migrate review) — then the corpus is re-migrated.

Each corpus lands as a **`.wo` bundle** (decisions.md D38,
`docs/spec/toolchain/wo_bundles.md`): its migrated source and tests live in the tree, its
object, manifest and declarations-only interface are compiled once per
target and With ABI, and a normal compiler build links the existing object
instead of recompiling the corpus. The compiler embeds every bundle's
object and interface (never the source: Sema on a corpus costs seconds
per program); user programs automatically link the ones they reference.

Layout: each bundle's source is checked in under `lib/std/engines/<corpus>/`
(D146) exactly as pcre2's and zlib's are — generated, never hand-edited
(D112: a corpus moves only by re-promotion, for a pin move, a migrator-pin
bump it needs, or a ruling that breaks its output), and under the stdlib tree
because a bundle's symbols hash the module's canonical `<embedded-std>/…`
path, which that location names whether or not the source is embedded
(`docs/spec/toolchain/wo_bundles.md`, "Object build"); facades in
`lib/std/collections.w`, `lib/std/collections/*.w` and `lib/std/algorithms.w`;
the corpora lanes (`<corpus>-test`, `:test`) run every bundle's upstream
tests, the fresh migrations (`<corpus>-test-fresh`, `corpus-migrator-gate`)
and `wo-drift` run at the seed-cut and release tier (D131,
`:release-checks`). A corpus is compiled against one data model, explicit in
its text (D156: fixed integer widths, `pub const C_DATA_MODEL`; only `char`
stays `c_char`, the target's builtin, D155), so one promoted corpus
compiles on every seed platform.

## Facade rules

- **The facade is the ownership boundary.** Engines see bytes and
  callbacks; the facade decides what a `&T` view is (D22/D27), what
  `remove` transfers, when elements drop, and how Drop-class elements are
  released when the container drops. The drop audit gains cells per facade
  (fully consumed, partially consumed then dropped, zero elements).
- **One primary engine per abstraction**, selected in the facade map above.
  Benchmark it against comparison engines under identical compilation and
  record the numbers next to the facade.
- **A complexity fixture per facade** (insert N descending then ascending,
  lookups, removals; a wall-clock bound an O(n²) cliff cannot meet), run in
  the battery. This is the guard that was missing.
- **Node ownership for intrusive engines** (TommyDS): the facade owns node
  storage (a Vec of nodes with stable addresses, or the engine's own
  blocked array) so that no user value is ever aliased by an engine pointer
  the facade does not control.
- **No `@[c_export]`, no `with_*` externs** in facades or migrated output
  (§Runtime Architecture, D30).

## What the facade looks like

We already ship two facades over migrated corpora, and they are the
template: `lib/std/zlib.w` over the migrated zlib modules and
`lib/std/regex.w` over migrated pcre2. Everything below generalizes what
those two do; nothing is a new mechanism.

**The pattern, as zlib and regex do it today**

1. *Import the raw modules directly.* `std.zlib` is
   `use std.engines.zlib.defs / compress / deflate / uncompr / inflate` — the
   migrated corpus as ordinary With modules. The corpus package never
   shares its dotted path with the facade (`std.engines.zlib` / `std.zlib`,
   `std.engines.pcre2` / `std.regex`): the frontend's parent-module import fallback
   would otherwise pull the facade into the `--no-prelude` bundle build
   (`docs/spec/toolchain/wo_bundles.md`). `std.regex` imports `std.engines.pcre2` through the
   bundle interface; C4 retired the `with_regex_*` runtime shims in #1101.
2. *A With error type over engine codes.* `ZlibError { code, message }`
   with `zlib_code_error(Z_DATA_ERROR) -> "invalid or corrupt zlib data"`;
   `RegexError { code, offset, message }`. Engine integers never escape.
3. *An owning handle for engine state.* `Regex { ptr: *const i8, … }`:
   the compiled code lives in engine memory, the With value owns it, and
   `move fn drop()` releases it (`pcre2_code_free`). Ownership of the
   engine resource is exactly as visible and as checked as any other
   With value's.
4. *Marshalling at the boundary only.* `&Vec[u8]` becomes `*const u8`
   for the call (`zlib_vec_data`); results come back copied into owned
   With values (`zlib_copy_from_raw` → `Vec[u8]`; capture spans →
   `Vec[i32]`, then the raw buffer is freed). Raw struct plumbing
   (`z_stream_s`, `inflateInit2_`, `sizeof[z_stream_s]()`) is inside one
   `unsafe fn` per operation. Nothing raw is stored in a public field of
   a value the user can copy.
5. *The surface is With idiom.* `Result[Vec[u8], ZlibError]`,
   `Option[Captures]`, `&str` in, owned out; receiver modes say who
   mutates (`fn` reads, `mut fn` mutates, `move fn` consumes).

**What containers add to that pattern**

A regex holds engine state; a container holds the *user's* values. So a
container facade owns two things: the engine handle, and the storage of
every `T` the engine indexes.

- *Storage.* Engines are `void*` + `elem_size` (c-algorithms, STC's raw
  instantiations) or intrusive-node (TommyDS). The facade hands the engine
  `sizeof[T]()` (spec §29, `sizeof[i32]()`) and moves each inserted value
  into engine-owned or facade-owned storage with a stable address; for
  intrusive engines the facade owns a node arena so an engine pointer never
  aliases a value the facade does not control. This is the same move the
  current `Vec[T]`/`HashMap[K, V]` facades make into `rt_core` storage.
- *Views.* A lookup returns the engine's pointer to the value's storage,
  which the facade types as `&V` — D22/D27: `get` observes, the binding
  names what is there, no copy. View liveness across a mutating call is
  enforced by the facade's receiver modes exactly as for `Vec` today
  (§15.17).
- *Transfers.* `remove` copies the value's bytes out into an owned `V`,
  tells the engine the slot is free, and returns `Option[V]` — the D27
  transfer, never a second live copy.
- *Drops.* `move fn drop()` walks the engine, drops every held `T`
  (Drop-class elements have destructors the engine cannot know about),
  then frees the engine. The drop audit gets one cell per facade for:
  empty, full, after partial removal, after a consuming iteration
  abandoned midway (D33: the iterator owns the tail).
- *Callbacks.* Engines take `int (*cmp)(const void*, const void*)` and
  hash functions. A generic engine adapter `RbTree[K: Ord, V]` supplies a
  monomorphized With `fn` per `K` (With generics are monomorphized, so
  `fn(*const u8, *const u8) -> i32` wrapping `K < K` exists per
  instantiation), plus a context pointer where the engine offers one.
  With's `fn` values are first-class (the iterator adapters already carry
  `fn(T) -> U`), and a With `fn` already crosses into engine code as a
  callback today: `std.channel` hands the runtime a
  `drop_fn: *const fn(*mut u8) -> Unit` per element type.
- *Iteration.* `iter()` is an `ephemeral` cursor over the engine's
  traversal yielding `&T` views (the `VecIter` shape); `into_iter()`
  transfers elements out in order and its drop releases the rest.

**Sketch: an internal `RbTree[K, V]` adapter over c-algorithms**

This illustrates ownership for a comparison engine. The selected public
`OrderedMap` uses STC's `smap`; `BTreeMap` uses M*LIB's B+ tree.

```
use std.engines.c_algorithms.rb_tree        // raw: RBTree, rb_tree_new(cmp), rb_tree_insert(tree, key, value), rb_tree_lookup, rb_tree_remove, rb_tree_free …

type RbTree[K, V] {
    tree: *mut RBTree,              // engine handle (raw)
    nodes: EntryArena[K, V],        // facade-owned stable storage for (K, V)
}

impl[K: Ord, V] RbTree[K, V]:
    pub fn new():
        RbTree { tree: rb_tree_new(rb_compare[K]), nodes: EntryArena.new() }
    pub fn get(key: &K) -> Option[&V]:            // observes: engine pointer typed as a view
        let node = rb_tree_lookup_node(self.tree, key as *const u8)
        if node == null: None else: Some(self.nodes.value_view(node))
    pub mut fn insert(key: K, value: V) -> Option[V]:  // returns the displaced value, if any
        …move (key, value) into the arena; rb_tree_insert with the slot's address…
    pub mut fn remove(key: &K) -> Option[V]:      // transfers out; slot freed; no second copy
    pub fn iter() -> RbTreeIter[K, V]             // ephemeral cursor: rb_tree_root_node → successor walk, yields (&K, &V)
    move fn drop():                                // drop every (K, V) in the arena, then rb_tree_free

fn rb_compare[K: Ord](a: *const u8, b: *const u8) -> i32:   // the monomorphized callback
    …view both as &K and compare…
```

The engine never sees `K` or `V`; it sees addresses and the comparator.
The facade never re-implements the tree; it owns values and translates
between With idiom and the engine's calls — the zlib/regex division.

**Sketch: `Vec[T].sort` over STC's instantiations (D37 consequence)**

STC's sort is a template; raw migration yields `sort_i32`, `sort_i64`,
`sort_cstr`, … for the shapes the corpus instantiates. A generic
`Vec[T].sort_by(cmp: fn(&T, &T) -> i32)` cannot call one of those for an
arbitrary `T`, so the facade dispatches on shape at compile time:

```
pub mut fn Vec[T].sort_by(cmp: fn(&T, &T) -> i32) -> Unit:
    comptime if T.is_copy() and sizeof[T]() == 8:                    // the word-sized shape STC instantiated
        stc_sort_u64(self.ptr, self.len, cmp-adapter)
    else:
        byte_sort(self.ptr, self.len, sizeof[T](), cmp-adapter)     // the void*/elem_size engine from another corpus
```

`comptime if` with type predicates (`T.is_copy()`, `sizeof[T]()`; spec
§comptime, "dead branches are not instantiated") is the tool. The shape set
is declared in one place next to the facade, benchmarked, and extended by
adding an instantiation to the corpus's build inputs — never by editing
migrated code. **Settled by D148 (2026-10-22):** arbitrary `T` goes through
the *slot shape* — the shapes unit (`facade_shapes.c` in `build/stc.w`,
likewise in `build/mlib.w`) instantiates the engine over pointers to
facade-owned slots whose head carries the C-ABI comparator and hasher that
dispatch to the With closures (`std.collections.stc_slot`, `mlib_slot`);
integer scalars take a *word shape* instantiation where measured (`Deque`,
`BTreeMap`/`BTreeSet`), picked per method by `comptime if`. No second
primary engine was substituted. `List.sort` today sorts `i64`/`u64`/`f64`
inline and every other `T` through slot references (D148's measurements in
the Phase 3 status).

**Sketch: `Deque[T]`, `PriorityQueue[T]`, `BitSet`**

Same anatomy: `Deque[T]` and `PriorityQueue[T]` own storage and wrap the engine's
ring buffer / binary heap through the raw modules with the callback per
`T`; `BitSet` is the simplest case — STC's `cbits` is not generic, so the
facade is an owning handle plus `mut fn set(i)`, `fn test(i) -> bool`,
iteration over set bits, and `move fn drop()`, the `Regex` shape exactly.

**Facade surfaces (the contracts the fixtures pin)**

| Facade | Primary engine | Surface | Complexity contract |
|---|---|---|---|
| `HashMap[K, V]` / `HashSet[T]` | rt_core's insertion-ordered layout (D96, D149) | `get` observes, `insert` owns inputs, `remove` transfers, `iter()` views in insertion order | O(1) expected; delete O(cluster), no allocation (#939) |
| `UnorderedMap[K, V]` / `UnorderedSet[T]` | STC `hmap` / `hset` | the `HashMap` surface without a stated order | O(1) expected |
| `OrderedMap[K, V]` / `OrderedSet[T]` | STC `smap` / `sset` | ordered lookup, insertion, removal, range traversal | O(log n) lookup/insert/remove |
| `BTreeMap[K, V]` / `BTreeSet[T]` | M*LIB `m-bptree` | ordered lookup, insertion, removal, range traversal | O(log n) lookup/insert/remove |
| `PriorityQueue[T]` | STC `pqueue` | `push(T)`, `pop() -> Option[T]`, `peek() -> Option[&T]` | O(log n) push/pop, O(1) peek |
| `BinaryHeap[T]` (optional public type) | c-algorithms binary heap | owning heap operations | O(log n) push/pop, O(1) peek |
| `Deque[T]` | STC `deque` | `push_front/back(T)`, `pop_front/back() -> Option[T]`, `get(i) -> &T` | O(1) amortized ends, O(1) index |
| `BitSet` | STC `cbits` | `set/clear/test`, `count`, `iter()` | O(1) bit ops, O(n/64) count |
| `List[T].sort`, `sort_by`, `binary_search`, `lower_bound`, `upper_bound`, `reverse` | STC algorithms | generic sorting and search; stability promised only for a verified `stable_sort` | O(n log n), O(log n) |
| `Trie[V]` | c-algorithms trie | `insert(&str, V)`, `get(&str)`, prefix iteration | O(key length) |
| `SortedList[T]` | c-algorithms sorted array | sorted insertion, lookup, removal, views | O(log n) search, O(n) insert/remove |
| `SlotMap[T]` (native) | `rt_core` + FIFO free list (#936) | unchanged | O(1) insert/remove/lookup |

Each row gets its complexity fixture in the battery and its drop-audit
cells. These are facade planning sketches; existing language ownership and
view contracts remain authoritative. Engine selection follows the ruling
above, with benchmark evidence recorded during implementation.

## Phases and gates

**Phase 0 — measure first (small, immediate).**
The complexity-fixture lane and a stdlib inventory (`docs/spec/stdlib/stdlib_inventory.md`:
every structure and algorithm we need, its complexity contract, current
status). Engine validation needs this yardstick. SlotMap's native
free list (#936) lands here too. Gate: lane green on today's containers
with the known cliffs recorded as expected failures.

**Phase 1 — c-algorithms, whole.**
The first container corpus through the pipeline; non-macro C, so the
migrator work is the facade-shaped `void*` + callback idiom, not templates.
Facades: `Trie`, `SortedVec`, and an owning binary-heap adapter, optionally
exposed as `BinaryHeap`. RB/AVL trees and the hash table remain internal or
comparison engines. This phase does not replace the default hash maps,
`OrderedMap`, `PriorityQueue`, or `BTreeMap` with c-algorithms engines.
Gate: upstream `test/` passes under With; facades' complexity fixtures
green; drop audit green; comparison measurements recorded. #937 is retired
by the M*LIB-backed `BTreeMap`/`BTreeSet` work in Phase 4.

**Phase 1 status (2026-09-13, branch `c-algorithms-phase1`).**
- Corpus: pinned (`build/c_algorithms.w`, revision `23d45379`), migrated
  raw with `with migrate` (19 engine modules + `defs.w`), promoted to
  `lib/std/engines/c_algorithms/` as the third `.wo` bundle (`c_algorithms.wo`;
  `bundle.w` root, `c-algorithms-bundle-root-check`, drift lane with
  upstream's `test-cpp` as the harness). The build wires it exactly as
  zlib's bundle at every site (since 2026-09-14 through the corpus registry).
- Upstream tests: all 17 test programs pass under With with
  `ALLOC_TESTING`. Each test is its own whole migration (engine + framework +
  test) because the programs' globals are independent; the migration is
  promoted into `test/corpora/c_algorithms/` (one shared `engine/`, a
  `programs/<name>/` with each program's `defs.w` and test module), and the
  corpora lane `c-algorithms-test` (in `:test`) compiles those checked-in
  programs with the release binary and runs them. A migrate workspace runs
  in the build driver's own compiler, so re-migrating (pin change, migrator
  fix) needs a tree compiler as the driver:
  `WITH=out/release/bin/with out/release/bin/with build :c-algorithms-promote`;
  the seed's migrator is behind the tree and bails on Darwin's `assert`.
- Migrator fixes made for it, all general: a record forward-declared
  without a definition in a TU renders `= opaque` so a later TU's
  definition completes it whatever the file order (`_Trie` lost its body
  when `test-trie.c` sorted before `trie.c`).
- Facades (`std.collections.sorted_vec.SortedVec[T]`,
  `std.collections.binary_heap.BinaryHeap[T]`,
  `std.collections.trie.Trie[V]`, storage in
  `std.collections.engine_slot`): the facade owns every value in a heap
  slot the engine indexes by pointer; `get`/`peek` observe (`&T`),
  `remove`/`pop` transfer, `move fn drop` releases every held value, then
  the engine. Behavior tests, complexity fixtures (`test/complexity`) and
  drop-audit cells (`tools/drop_audit.w`) cover each. The RB/AVL trees,
  hash table, lists, queue, bloom filter and binomial heap remain internal
  comparison engines (migrated, tested, not facaded).
- Comparators: the engines' C callbacks receive one non-generic
  trampoline; each slot carries the facade's With comparator closure
  because a closure written in a generic function cannot yet be handed to
  C directly (#1135). Two more compiler gaps found and filed: nested
  stdlib modules cannot import a corpus `pub let` (#1136); ordering two
  views of a type without an `lt` method silently compared addresses
  (#1137, fixed in this branch: it is now a diagnostic).
- The branch's pre-facade compiler commits (31a347d4, 88f0ad31, 92c0c01d)
  regressed ~16 existing fixtures; root-caused and fixed (`docs/completed/handoff.md`
  §1c), plus the va_list call-site model (e7ddf116). The full battery is
  green at 4832bf0a.
- Comparisons of user types: ruled (decisions.md D41, 2026-09-13).
  `Ord.cmp(self: &Self, other: &Self)` backs `<`/`<=`/`>`/`>=` and
  `Eq.eq(other: &Self)` backs `==`/`!=`; fixed-name methods are optional
  overrides. The facades bound `T: Ord` and compare views with `<`/`>`
  directly. §11.7 carries the blessed wording (2026-09-14).

**Phase 2 — TommyDS, whole.**
Specialized indexing/storage engines: `hashtable`, `hashdyn`, `hashlin`,
tries, and `arrayblk`. Benchmark the hash engines against Phase 1's hash
table and today's `rt_core` engine; STC remains the selected default owning
map engine. The facade design item is node ownership (above).
Gate: `check.c` passes under With; benchmark table recorded; specialized
adapters have complexity and drop evidence. #939 remains a Phase 3 gate.

**Phase 2 status (2026-09-14, branch `tommyds-phase2`).**
- Corpus: pinned (`build/tommyds.w`, amadvance/tommyds `1f3727fc`),
  migrated raw with `with migrate` (the 13 units as modules + `defs.w`;
  `tommy.c`, upstream's amalgamation of those units, is excluded),
  promoted to `lib/std/engines/tommyds/` as the fourth `.wo` bundle (`tommyds.wo`;
  `bundle.w` root, `tommyds-bundle-root-check`, drift lane with upstream's
  `check.c` as the harness — module `check_`, since `check` is a prelude
  name). Wired as c-algorithms is at every site (through the corpus registry).
- Upstream test: `check.c` runs to `OK` under With (37 timed sections,
  every structure's insert/search/remove/sort paths, `tommy_hash` test
  vectors). The corpora lane `tommyds-test` (in `:test`) compiles it from
  the checked-in corpus with the release binary and runs it. Re-migration:
  `WITH=out/release/bin/with out/release/bin/with build :tommyds-promote`.
- Migrator fixes made for it, all general: `__builtin_clz/ctz/popcount/
  bswap` lower to the integer methods (`(x as u32).clz()`); a pointer to a
  function typedef is a function pointer; `qsort`/`rand`/`srand` and
  Darwin's mach clock are std.libc bindings (the clock modeled portably:
  the runtime's monotonic nanoseconds, timebase 1/1); a header's
  `static inline` definitions are published once by the unit of the same
  name and imported by every other unit (TommyDS keeps `tommy_hashdyn_search`,
  `tommy_hashlin_search`, `tommy_inthash_u32` in headers; before this every
  includer had a private copy and nothing outside the corpus could call
  them). A header no unit owns (`tommytypes.h`'s `tommy_ilog2`) keeps a
  private copy per includer.
- Node ownership, the facade design item: `std.collections.hash_index.
  HashIndex[K: Hash + Eq, V]` over `hashdyn`. The engine threads intrusive
  nodes it never allocates; the facade owns every node — one heap slot per
  entry holding the node (first, so the engine's node pointer is the slot),
  the With key comparator (fixed offset, read by the one C trampoline
  `hash_slot_compare`), the key and the value. `get` observes, `remove`
  and a replacing `insert` transfer, `clear`/`drop` walk the buckets and
  release every slot exactly once. Behavior test `behav_hash_index`,
  complexity row `hash-index` (`test/complexity/stdlib.w`), drop-audit
  cells `hash_index_*` (`tools/drop_audit.w`). `hashlin` (incremental
  resize) and `hashtable` (fixed) stay internal engines: same node
  protocol, so the facade would be the same file with three `init`
  calls; not a public surface until a facade needs it.
- Benchmark (`test/benchmark/hash_engines.w`, `with run`; i32 keys,
  n = 200000, ns per operation, median of three, Eric's laptop, `-O1`):

  | engine | insert | lookup | remove |
  |---|---|---|---|
  | `rt_core` HashMap[i32, i32] | 41 | 9 | 58 |
  | HashIndex[i32, i32] (hashdyn, facade) | 32 | 3 | 26 |
  | tommy_hashdyn raw (caller-owned nodes) | 18 | 5 | 15 |
  | tommy_hashlin raw | 24 | 6 | 14 |
  | tommy_hashtable raw (fixed, n buckets) | 4 | 7 | 10 |
  | c-algorithms hash_table raw | 47 | 1 | 25 |

  The facade's cost over the raw engine is one heap slot per entry and
  the key hash + comparator call; its lookup reuses one probe slot.

  STC remains the selected default owning map engine (Phase 3); the
  numbers above are the comparison the plan asked for, not a selection.

**Phase 3 — STC, whole: the macro-migrator campaign.**
STC is valuable because its template mechanism is nasty: containers are
instantiated by defining parameters and including the header, so one
header is N types. Under D37 the migrator's job is exactly the faithful
one: expand the preprocessor and emit one raw copy per instantiation the
corpus contains (its library, tests, and examples instantiate many). No
lifting to generics in the migrator. The migrator work is making that
expansion correct — parameterized includes, `#define`-driven naming,
the specialization macros — with no STC-specific rule in `with migrate`.

The consequence is the facade's to absorb, and it is the design item to
settle in this phase, not in the migrator: a generic With surface over a
templated engine can only be generic in one of two ways —
(a) the facade declares the finite set of engine instantiations it exposes
(`Deque` over the element shapes the stdlib actually needs: word-sized
POD, `str`, fat views — STC's own instantiation set, extended in the
corpus's build inputs when a shape is missing), or
(b) the facade routes arbitrary `T` to a `void*` + `elem_size` engine from
c-algorithms/TommyDS and keeps the STC engine for the concrete shapes it
covers. Both keep the migrator raw, but the second approach predates the
engine-selection ruling above and is a comparison approach, not approval
to replace STC for arbitrary `T`. Phase 3 must demonstrate how the selected
STC engines support the generic facade contracts and record that design
with benchmark evidence.
Facades: `Vec`, `Deque`, `Stack`, `Queue`, `PriorityQueue`, `List`,
`HashMap`/`HashSet`, `OrderedMap`/`OrderedSet`, `BitSet`, spans, and
generic sequence algorithms including sorting and searches (#940).
Use `cstr` selectively while preserving With's `str` semantics.
`VecIntoIter` must use a linear cursor (#938); default hash deletion must
meet the no-allocation complexity contract (#939).
Gate: STC's own `tests/` pass under With with no corpus-specific migrator
code; facade complexity fixtures and drop audit green; #938, #939, and
#940 closed. Evaluate `stable_sort` separately against its stability
contract before exposing it.

**Phase 3 status (2026-10-22, branch `stc-migrator`): the pipeline half.**
- Corpus: pinned (`build/stc.w`, stclib/STC `fc5c0587`), the `src/` library
  units migrated whole in STC_HEADER linkage against the header tree
  (`Corpus.include_dirs`), plus a staged `ucd` unit for the Unicode tables
  upstream compiles only into cregex; promoted to `lib/std/engines/stc/` as the
  fifth `.wo` bundle (drift harness: `examples/strings/replace.c`). Out,
  loudly: `cregex` (setjmp) and `stc_core` (the coroutine runtime: its
  records carry bitfields); the same rule keeps `hmap_test` migrated but
  not compiled. A record with bitfields imports opaque (§16.9); the brief
  is #2553 and STC's `hmap`/`hset`, the ruled default `HashMap`/`HashSet`
  engine, wait on it.
- Upstream tests: 7 of the 8 ctest units run under With, 19 tests, all
  pass (`stc-test-fresh`, `stc-test`). Each unit is its own whole migration
  (a unit's `#define T Intmap ..` is an hmap in one test and a sorted map in
  another) with the library units upstream links; a generated runner calls
  every registered test from its `ctest` record, fixtures through
  setup/teardown; the assertions are a With harness
  (`test/corpora/stc_harness`) exporting ctest.h's C names and counting
  failures instead of longjmp. Promoted under `test/corpora/stc/` (one
  shared `engine/`, `programs/<name>/`).
- Migrator rules made for it, all general (basic-test cases in
  `bs_check_migrate_stc_expression_forms`): `va_copy`, and `va_start`/
  `va_copy` in goto bodies; hexadecimal float literals; a C type declared
  under a builtin type's name is renamed (#2552); an unnamed member record
  referenced outside its parent is named as its parent's translation names
  it; a string literal in a variadic position is a C string; `[index] =
  value` array designators; a record copied from a value is bound before
  its address is taken (#2551); one definition two units include is one
  symbol; a std corpus's foreign externs need no `unsafe` wrapper.
  `std.libc` gained `rewind`, `putchar`, `struct tm`, `strftime`, `mktime`,
  `timeval`/`gettimeofday` (the runtime's new wall clock in nanoseconds).
  The pinned corpora re-promoted under this migrator (D112).
- Compiler defects found and filed: #2552 (a std-package `pub type isize`
  shadows the builtin package-wide), #2554 (a `@[c_export]` definition
  dropped by a same-named `extern fn`; a bare `@[c_export]` exports
  nothing), #2555 (std.sync under `--no-prelude`).
- Bitfields (D147, 2026-10-22, branch `bitfields`): a migrated record with
  bitfields keeps C's layout (storage units, a getter and a setter per
  member, stores that truncate, one layout per data model or a loud
  refusal). `stc_core` joins the engine corpus and `hmap_test` the test
  corpus: 8 of 8 ctest units pass under With, fresh and promoted. The
  engines namespace is `std.engines.<library>` (D146). The test lane maps
  each program's staging directory out of the baked `__FILE__` spellings
  (`with migrate --macro-prefix-map`), which keeps one shared `engine/`.
- The facade half (D148, 2026-10-22, branch `stc-facades`): the
  generic-over-templates design item is settled by the slot shape —
  one hand-written C unit in the corpus's build inputs (`facade_shapes.c`,
  build/stc.w) instantiates STC's templates per shape: `hset`, `sset`,
  `pqueue`, `deque` over pointers to facade-owned slots whose head holds the
  C-ABI callbacks that dispatch to the With comparator and hasher
  (`std.collections.stc_slot`), `deque` of words, `sort` over slot
  references and over i64/u64/f64, and `cbits`. Two general migrator rules
  came out of it (a recursive `pub fn` keeps `-> Unit`, D143; a header
  function no unit owns is published by its sole includer). Facades: `PriorityQueue`, `OrderedSet`,
  `OrderedMap`, `Deque`, `BitSet`, `List.sort`/`sort_by`/`binary_search`/
  `lower_bound`/`upper_bound`/`reverse` (#940); the runtime's `remove(0)`
  advances the buffer's start (D115), so consuming iteration is O(1) per
  element (#938; the native `BTreeMap`'s descending rebuild became linear
  with it, its ascending scan and `BTreeSet` stay #937). Each has a behavior fixture, complexity rows
  (`test/complexity/stdlib.w`) and drop-audit cells. Benchmark
  (`test/benchmark/stc_engines.w`, n = 100000 i32, ns per operation,
  insert/lookup/remove): PriorityQueue 18/0/109 against the c-algorithms
  BinaryHeap 17/0/111; OrderedSet 197/103/237 against the native BTreeSet
  4371/481/4525 (n = 4000, #937) and the c-algorithms SortedList
  6175/83/10435 (n = 20000); Deque 11/0/11 against List 2/0/1 (the slot
  allocation per element: the word shape is the next row when a Copy
  `T` needs it); `List.sort` 34 ns per i64, 200 ns per pair through
  references.
- Ruled on the briefs (2026-10-22): D149 — `HashMap`/`HashSet` keep
  rt_core's insertion-ordered layout (D96); STC `hmap`/`hset` is the
  comparison engine and backs `UnorderedMap`/`UnorderedSet` under their own
  names. D148 blessed with two conditions, both met: `Deque` stores the
  integer scalars inline (the word shape) and says so in its doc; the
  sole-includer publication rule is its own ruling, D150, with a fixture.
  Measured (`test/benchmark/stc_engines.w`, n = 100000 i32, ns per
  operation insert/lookup/remove): `Deque[i32]` 2/0/0 (word shape) against
  `Deque[Pair]` 12/0/10 (slot shape) and `List` 2/0/1; `UnorderedSet`
  69/53/105 against `HashSet` 75/26/25 — the facade allocates a probe slot
  per lookup and dispatches through its callbacks, so lookup and remove
  trail the inline builtin; a direct word-key instantiation of `hset` is
  the next row when a hot path needs it.
- Open: `d[i]` on `Deque` waits on #2560; `stable_sort` evaluated
  separately; the unfilled facade rows under "What remains". Phase 4 is
  done (below).
- Data model (D155/D156, 2026-10-23/24): the corpus is compiled against one
  data model explicit in its text (fixed widths; `c_char` the target's
  builtin), the promoted test programs too; every bundle compiles on each
  seed platform, and the stc harness speaks the corpus's `i64` where the C
  header says `long` (#2607).

**Phase 4 — M*LIB `m-bptree.h`, surgical.**
Only the B+ tree, providing `BTreeMap`/`BTreeSet` and retiring their
sorted-Vec implementation (#937). Benchmark against Phase 1's RB/AVL
comparison engines; `OrderedMap`/`OrderedSet` retain STC's `smap`/`sset`.
Gate: M*LIB's bptree tests pass under With; facade complexity fixtures and
drop audit green; comparison measurements recorded; #937 closed.

Status (2026-10-22, D151):
- The corpus: `build/mlib.w`, `lib/std/engines/mlib` (`m-core.h`, `m-bptree.h`,
  the facade shapes unit `BPTREE_DEF(mlib_slot_tree, 16, mlib_slot, …)` over
  slot pointers, D148; upstream's multimap example as the drift harness and
  the `mlib-test`/`mlib-test-fresh` lanes). M*LIB pinned at
  93cddfb56c32976d8aeefd45ef9094167f64b285. Migrated with `M_USE_STDIO=0`
  (the `FILE*` parsers and printers out) and `M_RAISE_FATAL(...)=abort()`;
  `<stdio.h>` forced for the units (the corpus model's `forced_includes`).
- Migrator rules it exposed, each general with a fixture (commit "The
  migrator rules M*LIB's B+tree exposed"): typedef'd arrays and pointers,
  `case A: default:`, call arguments translated once per level (the 2^depth
  tower), discarded `sizeof`/compound literals, `(T){0} = v`, an anonymous
  record a compound literal instantiates, one enum type everywhere, a field
  of a value read directly, strlen's `size_t`; std.libc's strtoll family.
- `BTreeMap`/`BTreeSet` are facades over the slot shape (D151); the compiler's
  knowledge of their List layout is retired (traversal by `iter()` under
  §13.5, literals and comprehensions from the recorded `new()` contract).
  Complexity rows `btree-map-*`/`btree-set-*` PASS (XFAIL #937 before);
  drop-audit cells `btree_map_*`, `btree_set_*`; `behav_btree_engine.w`.
- Measured (`test/benchmark/stc_engines.w`, n = 100000 i32, ns/op median of
  3, insert/lookup/remove): BTreeSet 945/444/617 and BTreeMap 936/438/611 over
  the slot shape, beside OrderedSet (STC sset, AA-tree) 195/107/223 and the
  retired sorted-List BTreeSet (n = 4000: 4371/481/4525). The B+tree pays a
  key clone per insert and per separator, a probe allocation per lookup and
  three C-ABI callbacks per comparison; the word shape for integer keys
  (D148's condition) is the next row when a hot path needs it.
- Upstream's `tests/test-mbptree.c` runs under With (2026-10-23): migrated
  whole with `m-core.h`, `m-string.h`, `m-bptree.h`, `tests/test-obj.h` and
  `tests/coverage.h` in upstream's test configuration (`M_USE_STDIO=1`),
  checked in under `test/corpora/mlib/programs/test_mbptree`, compiled with
  the prelude off and run by `mlib-test-programs` (in the `mlib-test` lane)
  and `mlib-test-programs-fresh` (the migrator gate); all thirteen tests
  exit 0. The rules it exposed, each general with a fixture: std.libc's
  fscanf/ungetc/str* families, a declaration in a switch arm, a
  conditional callee, and C11 `_Generic` selected by the controlling
  expression's type through the macros that spell it (libclang peeled it
  to its default arm). The library corpus was not re-promoted (D112).
- The word shape (D148, 2026-10-23): an integer key (`i8`..`i64`, `u8`..`u64`,
  `isize`, `usize`) is the engine's own int64_t (`BPTREE_DEF2(mlib_word_tree,
  16, int64_t, M_BASIC_OPLIST, void*, M_PTR_OPLIST)` in the shapes unit; an
  unsigned 64-bit key flips its sign bit, which keeps its order), holding the
  facade's entry; `comptime if btree_is_word[K]()` picks it per method, as
  `Deque` does. Measured (same harness): BTreeSet[i32] 188/36/171 and
  BTreeMap[i32] 187/36/173 beside OrderedSet (STC sset) 207/118/258 and the
  slot shape with `str` keys 2343/1043/1288 (BTreeSet) and 2301/1038/1306
  (BTreeMap). Fixture behav_btree_word_keys (every width, both signs, the
  extremes, drops); complexity rows `btree-*-str-*` keep the slot shape
  measured; drop-audit cells `btree_map_str_*` likewise. The corpus was
  re-promoted under `inputs:` (D112: the shapes unit is the corpus's source).

Order is fixed by risk: 1 validates the whole-corpus pipeline on a
container library, 2 adds the performance yardstick, 3 is the campaign, 4
is a bounded extra.

## What "done" means

Each phase is done only when: the corpus migrates from its pin with zero
hand edits; its upstream tests pass under With; every migrator change made
for it is general (no corpus name in `with migrate`); the facades it feeds
have complexity fixtures and drop-audit cells; the selected engine is
implemented with benchmark evidence; and the issues it retires are closed
with evidence.
A green build with a silently mishandled corpus is 0% done (§"Good enough
for now").

## What remains (2026-10-24)

Every phase gate is met. The 2026-10-24 close-out landed `Stack`, `Queue`,
`LinkedList`, `stable_sort`/`stable_sort_by`/`shuffle`, the word shapes for
`UnorderedSet` and `PriorityQueue`, the shared slot and entry lifetime in
`stc_slot` (the facades' `unsafe` is the engine call itself), and #2560
(`IndexPlace` on a generic user type). What the facade map still names and
the tree does not have:

1. **`List[T]` over STC `vec` — ruled, D157 (2026-10-24).** rt_core stays
   the engine: the compiler's knowledge of the layout (literals,
   comprehensions, `for`, `xs[i]` as a place, push/pop, copy-on-write, the
   counted copy class) is the engine; STC `vec` is the benchmark's
   comparison row, never a dependency of the runtime. The sourcing rule
   was written for library containers, not for types the compiler itself
   lowers to. Reopens on a measured gap in the comparison row or a feature
   rt_core lacks.
2. **`Span[T]` — dropped, D158 (2026-10-24).** `[]T` (§4.8a) and D119's
   arrays are the views; multi-dimensional and strided slicing
   (`tensor[2:5, :, newaxis]`, the design goal) is a language feature over
   them. `cspan` was the one row whose reason to import was shape, not
   hardening; it stays a migrated engine. Reopens when a numeric program
   needs strided views first, by scheduling the language feature.
3. **STC `cstr`** as an internal string engine: not started; `str` keeps its
   D111 contract whatever engine sits under it, and nothing measured asks
   for a change.
4. **Internal engines without facades** (TommyDS `arrayblk`, `hashlin`,
   `hashtable`; c-algorithms RB/AVL trees, hash table, lists, queue, bloom
   filter, binomial heap): migrated, tested in the corpora lanes, exposed
   only when a facade needs them (open question 3).
5. **Generic heap utilities** (`heapify`, `push_heap` over a `List`): no
   use case beyond `PriorityQueue`/`BinaryHeap`; stays unexposed until one.
6. **The engine boundary's `unsafe` — ruled, D159 (2026-10-24); a new
   migrator stage, non-compliant until it lands.** The migrator emits a
   safe signature where the function's body proves the contract: (a) a
   `mut self` receiver when the engine handle is the first parameter, or
   an out-parameter the body writes on every returning path presented as
   a returned `Copy` value (`T` or `(status, T)`; written conditionally
   stays `unsafe`; no new parameter mode), (b) a stored argument that a
   destroyer in the same corpus frees along the same path (store alone is
   "stored, ownership unknown" and stays `unsafe`), (c) a returned
   pointer's origin; an unproved point keeps `pub unsafe fn` with the
   point named in the generated comment; the drift lane diffs the
   inferred contracts and a change is red until a human looks; a migrator
   generation bump, so promoted corpora keep compiling raw until their pin
   or a ruling moves them (D112). The campaign issue is filed with the
   ruling; the STC facades drop their engine-call `unsafe` at the corpus's
   next re-promotion.
7. **The compiler defects the facades found are closed** (2026-10-24):
   #2560 (`IndexPlace`/`IndexGet` on a generic user type; `Deque` and
   `Stack` spell `d[i]`), #2565 (a tuple type argument at a static call),
   #1135 and #1136 (no longer reproduce; fixtures pin them, the
   `BinaryHeap` workaround is gone).

## Open questions for Eric

1. *Settled (D148, 2026-10-22).* D37 settles that the migrator is raw, and
   the facade map settles primary engines; arbitrary-`T` support over STC's
   concrete instantiations is the slot shape, with word shapes where
   measured. No comparison engine became a default.
2. *Settled (D131, D112).* The corpora live under `lib/std/engines/`
   (D146); the promoted bundles' upstream tests run in `:test`
   (`<corpus>-test`), the fresh migrations and `wo-drift` at the seed-cut
   and release tier (`:release-checks`), and a corpus re-migrates only on
   a pin move, a migrator-pin bump or a ruling (D112).
3. The facade map above settles primary engines and the broad public
   grouping. Optional public types (`BinaryHeap`, `SortedList`, `Stack`,
   `Queue` and `LinkedList` are public; `Span` and the specialized
   indexes/storage are not) and detailed new API signatures remain
   facade-PR decisions, D98 delegation applying outside C interop,
   ownership and safety.
