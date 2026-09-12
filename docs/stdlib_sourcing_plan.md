# Stdlib sourcing: three migrated corpora, one facade

Status (2026-09-12): PCRE2 and zlib share the bundle pipeline. Phase 0 is
implemented with final verification in progress; Phase 1 migration is in
progress; Phases 2–4 remain planned. Engine selections were ruled on
2026-09-12; module grouping is provisional.
Companion: `docs/harden_migrate.md` (the migrator plan
this campaign exercises), `docs/harden_plan.md` item 7.

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
names do not automatically become permanent standard-library API names.
This ruling supersedes the earlier open engine choices in this plan.
Benchmarks validate the selected engines and compare alternatives; changing
a primary engine requires a new ruling.

| `lib/std` facade | Primary engine | Secondary / comparison engine | Notes |
| --- | --- | --- | --- |
| `Vec[T]` | **STC `vec`** | TommyDS `array` | General growable contiguous sequence |
| `Deque[T]` | **STC `deque`** | — | Double-ended queue |
| `Stack[T]` | **STC `stack`** | — | Can remain a thin facade over the chosen sequence engine |
| `Queue[T]` | **STC `queue`** | c-algorithms queue | FIFO queue |
| `PriorityQueue[T]` | **STC `pqueue`** | c-algorithms binary heap | Heap-backed priority queue |
| `List[T]` | **STC `list`** | c-algorithms list / TommyDS list | General linked list |
| `HashMap[K, V]` | **STC `hmap`** | TommyDS `hashdyn` / `hashlin`; c-algorithms hash table | Default owning hash map |
| `HashSet[T]` | **STC `hset`** | TommyDS hashing machinery | Same hash-table family as `HashMap` |
| `OrderedMap[K, V]` | **STC `smap`** | c-algorithms RB tree / AVL tree | Public ordered associative map |
| `OrderedSet[T]` | **STC `sset`** | c-algorithms RB tree / AVL tree | Public ordered set |
| `BTreeMap[K, V]` | **M*LIB `m-bptree`** | — | B+ tree-backed ordered/indexed map |
| `BTreeSet[T]` | **M*LIB `m-bptree`** | — | B+ tree-backed ordered set |
| `Trie[V]` | **c-algorithms trie** | TommyDS `trie` / `trie_inplace` | Prefix-keyed lookup |
| `BitSet` | **STC `cbits`** | — | Dynamic bitset |
| `Span[T]` | **STC span machinery** | — | Non-owning contiguous view |
| `String` / internal string engine | **STC `cstr` where useful** | Existing With string implementation | Use STC selectively; With’s existing `str` semantics remain the public contract |
| `SortedVec[T]` | **c-algorithms sorted array** | STC algorithms + `Vec` | Sorted contiguous collection |
| `ChunkedVec[T]` / internal block storage | **TommyDS `arrayblk`** | — | Growth without one large contiguous realloc; possibly internal rather than public |
| `Index[T]` / intrusive object index | **TommyDS `hashtable` / `hashdyn`** | — | Internal/specialized rather than everyday `std` API |
| `IncrementalHashIndex[T]` | **TommyDS `hashlin`** | — | Specialized incremental-resize hash index; likely internal |
| `BinaryHeap[T]` | **c-algorithms binary heap** | STC `pqueue` | Could expose separately from `PriorityQueue` if desired |
| `RbTree[K, V]` | **c-algorithms RB tree** | — | Could stay internal behind `OrderedMap` |
| `AvlTree[K, V]` | **c-algorithms AVL tree** | — | Alternate/internal ordered-tree engine |
| `sort` | **STC algorithm layer** | — | With-generic facade over migrated implementation |
| `stable_sort` | Evaluate / implement separately | — | Only map if upstream provides the required stability contract |
| `binary_search` | **STC algorithms** | c-algorithms sorted-array logic | Shared generic algorithm |
| `lower_bound` / `upper_bound` | **STC algorithms** | c-algorithms | Useful with `Vec`, `Span`, sorted collections |
| `reverse` | **STC algorithms** | — | Generic sequence algorithm |
| `shuffle` | **STC algorithms** | — | With RNG passed through facade |
| `find` / search helpers | **STC algorithms** | — | Where available and semantically appropriate |
| Heap algorithms | **STC `pqueue` / c-algorithms heap** | — | Support `PriorityQueue` and possibly generic heap utilities |

The public surface is grouped roughly as follows:

- `std.collections`: `Vec`, `Deque`, `Stack`, `Queue`, `PriorityQueue`,
  `List`, `HashMap`, `HashSet`, `OrderedMap`, `OrderedSet`, `BTreeMap`,
  `BTreeSet`, `Trie`, `BitSet`, and perhaps `SortedVec`.
- `std.slice` / `std.span`: non-owning sequence/view machinery.
- `std.algorithms`: `sort`, `binary_search`, bounds searches, `reverse`,
  `shuffle`, and the other generic sequence algorithms.

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

Per corpus, exactly what `build/pcre2.w` does today:

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
`docs/wo_bundles.md`): its migrated source and tests live in the tree, its
object, manifest and declarations-only interface are compiled once per
target and With ABI, and a normal compiler build links the existing object
instead of recompiling the corpus. The compiler embeds every bundle's
object and interface (never the source: Sema on a corpus costs seconds
per program); user programs automatically link the ones they reference.

Layout: each bundle's source is checked in under `lib/std/<corpus>/`
exactly as pcre2's (`lib/std/re/`) and zlib's (`lib/std/zl/`) are —
generated, never hand-edited, and under the stdlib tree because a bundle's
symbols hash the module's canonical `<embedded-std>/…` path, which that
location names whether or not the source is embedded
(`docs/wo_bundles.md`, "Object build"); facades in `lib/std/collections.w`
and a new `lib/std/algorithms.w`; a `corpora` battery lane that runs every
bundle's upstream tests, plus the `wo-drift` lane from `docs/wo_bundles.md`.

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
   `use std.zl.defs / compress / deflate / uncompr / inflate` — the
   migrated corpus as ordinary With modules. The corpus package never
   shares its dotted path with the facade (`std.zl` / `std.zlib`,
   `std.re` / `std.regex`): the frontend's parent-module import fallback
   would otherwise pull the facade into the `--no-prelude` bundle build
   (`docs/wo_bundles.md`). `std.regex` imports `std.re` through the
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
use std.c_algorithms.rb_tree        // raw: RBTree, rb_tree_new(cmp), rb_tree_insert(tree, key, value), rb_tree_lookup, rb_tree_remove, rb_tree_free …

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
migrated code. This earlier sketch illustrates shape adaptation; it does
not settle arbitrary-`T` support for the selected STC engine. That support
must be demonstrated in Phase 3 without silently substituting another
primary engine.

**Sketch: `Deque[T]`, `PriorityQueue[T]`, `BitSet`**

Same anatomy: `Deque[T]` and `PriorityQueue[T]` own storage and wrap the engine's
ring buffer / binary heap through the raw modules with the callback per
`T`; `BitSet` is the simplest case — STC's `cbits` is not generic, so the
facade is an owning handle plus `mut fn set(i)`, `fn test(i) -> bool`,
iteration over set bits, and `move fn drop()`, the `Regex` shape exactly.

**Facade surfaces (the contracts the fixtures pin)**

| Facade | Primary engine | Surface | Complexity contract |
|---|---|---|---|
| `HashMap[K, V]` / `HashSet[T]` | STC `hmap` / `hset` | `get` observes, `insert` owns inputs, `remove` transfers, `iter()` views | O(1) expected; delete O(cluster), no allocation |
| `OrderedMap[K, V]` / `OrderedSet[T]` | STC `smap` / `sset` | ordered lookup, insertion, removal, range traversal | O(log n) lookup/insert/remove |
| `BTreeMap[K, V]` / `BTreeSet[T]` | M*LIB `m-bptree` | ordered lookup, insertion, removal, range traversal | O(log n) lookup/insert/remove |
| `PriorityQueue[T]` | STC `pqueue` | `push(T)`, `pop() -> Option[T]`, `peek() -> Option[&T]` | O(log n) push/pop, O(1) peek |
| `BinaryHeap[T]` (optional public type) | c-algorithms binary heap | owning heap operations | O(log n) push/pop, O(1) peek |
| `Deque[T]` | STC `deque` | `push_front/back(T)`, `pop_front/back() -> Option[T]`, `get(i) -> &T` | O(1) amortized ends, O(1) index |
| `BitSet` | STC `cbits` | `set/clear/test`, `count`, `iter()` | O(1) bit ops, O(n/64) count |
| `Vec[T].sort`, `sort_by`, `binary_search`, `lower_bound` | STC algorithms | generic sorting and search; stability promised only for a verified `stable_sort` | O(n log n), O(log n) |
| `Trie[V]` | c-algorithms trie | `insert(&str, V)`, `get(&str)`, prefix iteration | O(key length) |
| `SortedVec[T]` | c-algorithms sorted array | sorted insertion, lookup, removal, views | O(log n) search, O(n) insert/remove |
| `SlotMap[T]` (native) | `rt_core` + FIFO free list (#936) | unchanged | O(1) insert/remove/lookup |

Each row gets its complexity fixture in the battery and its drop-audit
cells. These are facade planning sketches; existing language ownership and
view contracts remain authoritative. Engine selection follows the ruling
above, with benchmark evidence recorded during implementation.

## Phases and gates

**Phase 0 — measure first (small, immediate).**
The complexity-fixture lane and a stdlib inventory (`docs/stdlib_inventory.md`:
every structure and algorithm we need, its complexity contract, current
status). Engine validation needs this yardstick. SlotMap's native
free list (#936) lands here too. Gate: lane green on today's containers
with the known cliffs recorded as expected failures.

Implementation (2026-09-12): [the inventory](stdlib_inventory.md) records the
current engines and planned algorithm families. `with build :stdlib-complexity`
is part of `:test`; [its fixtures](../test/complexity/README.md) check results,
N/4N runtime growth, and allocation requests with `--trace-alloc`. The known
#937/#938/#939 cost cliffs are explicit expected failures; incorrect results,
crashes, and invalid measurement controls fail the lane.

SlotMap now uses a FIFO free list and retires exhausted generations. Native
fixtures cover reuse order, growth, stale handles, exhaustion, and exact Drop
counts. Four SlotMap cells extend the drop audit. The runtime header grows from
48 to 56 bytes, and each slot uses a four-byte next link instead of a one-byte
occupancy flag; [ABI v4](with-abi.md) records that internal layout change.
This phase migrates no new C corpus and chooses no new public API names.

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

**Phase 2 — TommyDS, whole.**
Specialized indexing/storage engines: `hashtable`, `hashdyn`, `hashlin`,
tries, and `arrayblk`. Benchmark the hash engines against Phase 1's hash
table and today's `rt_core` engine; STC remains the selected default owning
map engine. The facade design item is node ownership (above).
Gate: `check.c` passes under With; benchmark table recorded; specialized
adapters have complexity and drop evidence. #939 remains a Phase 3 gate.

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

**Phase 4 — M*LIB `m-bptree.h`, surgical.**
Only the B+ tree, providing `BTreeMap`/`BTreeSet` and retiring their
sorted-Vec implementation (#937). Benchmark against Phase 1's RB/AVL
comparison engines; `OrderedMap`/`OrderedSet` retain STC's `smap`/`sset`.
Gate: M*LIB's bptree tests pass under With; facade complexity fixtures and
drop audit green; comparison measurements recorded; #937 closed.

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

## Open questions for Eric

1. D37 settles that the migrator is raw, and the facade map settles primary
   engines. Phase 3 still needs to demonstrate arbitrary-`T` support over
   STC's concrete instantiations; comparison engines do not silently
   become defaults.
2. Where the corpora live and whether all of them build in every battery
   (proposal: yes, in a `corpora` lane — the coverage is the point; cost is
   build time, measured in Phase 1).
3. The facade map above settles primary engines and the broad public
   grouping. Optional public types (`BinaryHeap`, `SortedVec`, specialized
   indexes/storage) and detailed new API signatures remain facade-PR
   decisions.
