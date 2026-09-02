# Stdlib sourcing: three migrated corpora, one facade

Status: PLAN (2026-09-01). Ruled in direction by Eric; nothing here is
implemented. Paths are proposals in the repo's existing conventions, not
part of the ruling. Companion: `docs/harden_migrate.md` (the migrator plan
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
free list (#936 — no mature C library ships generational slot maps), and the
intrinsic-integrated Vec and str, which stay as they are.

To confirm at pin time, not from memory: TommyDS's exact license text (its
`COPYING`), and that c-algorithms is `void*` + comparator callbacks
throughout (expected; it determines facade shape).

## Why the un-facaded code is not waste

Everything migrated compiles in the battery whether or not a facade uses
it. That gives:

- migration regression coverage on real generic C, forever;
- alternative engines under identical With compilation, so facades choose
  winners by benchmark, not by reputation (five migrated hash tables
  underneath, exactly one exposed);
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
`docs/wo_bundles.md`): its migrated source and tests are the bundle, its
object is compiled once per target and With ABI version, and a normal
compiler build links the existing object instead of recompiling the
corpus. The compiler embeds every bundle; user programs automatically
link the ones they reference.

Proposed layout (proposal, not ruling): the bundles' source checked in
under `lib/vendor/<corpus>/` the way pcre2's lives in `lib/std/re/`,
generated and never hand-edited; facades in `lib/std/collections.w` and a
new `lib/std/algorithms.w`; a `corpora` battery lane that runs every
bundle's upstream tests, plus the `wo-drift` lane from `docs/wo_bundles.md`.

## Facade rules

- **The facade is the ownership boundary.** Engines see bytes and
  callbacks; the facade decides what a `&T` view is (D22/D27), what
  `remove` transfers, when elements drop, and how Drop-class elements are
  released when the container drops. The drop audit gains cells per facade
  (fully consumed, partially consumed then dropped, zero elements).
- **One engine per abstraction**, chosen by benchmark across the corpora
  under identical compilation; the choice is recorded next to the facade
  with the numbers.
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
   `use std.zlib.defs / compress / deflate / uncompr / inflate` — the
   migrated corpus as ordinary With modules. (`std.regex` still reaches
   pcre2 through the `with_regex_*` runtime shims; that is the D30
   transitional seam, not the model. New facades import the corpus.)
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
  hash functions. A generic facade `BTreeMap[K: Ord, V]` supplies a
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

**Sketch: `BTreeMap[K, V]` over c-algorithms' red-black tree**

```
use std.c_algorithms.rb_tree        // raw: RBTree, rb_tree_new(cmp), rb_tree_insert(tree, key, value), rb_tree_lookup, rb_tree_remove, rb_tree_free …

pub type BTreeMap[K, V] {
    tree: *mut RBTree,              // engine handle (raw)
    nodes: EntryArena[K, V],        // facade-owned stable storage for (K, V)
}

impl[K: Ord, V] BTreeMap[K, V]:
    pub fn new() -> BTreeMap[K, V]:
        BTreeMap { tree: rb_tree_new(btree_compare[K]), nodes: EntryArena.new() }
    pub fn get(key: &K) -> Option[&V]:            // observes: engine pointer typed as a view
        let node = rb_tree_lookup_node(self.tree, key as *const u8)
        if node == null: None else: Some(self.nodes.value_view(node))
    pub mut fn insert(key: K, value: V) -> Option[V]:  // returns the displaced value, if any
        …move (key, value) into the arena; rb_tree_insert with the slot's address…
    pub mut fn remove(key: &K) -> Option[V]:      // transfers out; slot freed; no second copy
    pub fn iter() -> BTreeIter[K, V]              // ephemeral cursor: rb_tree_root_node → successor walk, yields (&K, &V)
    move fn drop():                                // drop every (K, V) in the arena, then rb_tree_free

fn btree_compare[K: Ord](a: *const u8, b: *const u8) -> i32:   // the monomorphized callback
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
migrated code. Where a byte engine is faster or simpler for all shapes,
the facade uses it for all shapes; the point is that both answers keep
the migrator raw.

**Sketch: `Deque[T]`, `Heap[T]`, `BitSet`**

Same anatomy: `Deque[T]` and `Heap[T]` own storage and wrap the engine's
ring buffer / binary heap through the raw modules with the callback per
`T`; `BitSet` is the simplest case — STC's `cbits` is not generic, so the
facade is an owning handle plus `mut fn set(i)`, `fn test(i) -> bool`,
iteration over set bits, and `move fn drop()`, the `Regex` shape exactly.

**Facade surfaces (the contracts the fixtures pin)**

| Facade | Engine candidates | Surface | Complexity contract |
|---|---|---|---|
| `HashMap[K, V]` / `HashSet[T]` | `rt_core` (today), c-algorithms hash-table, TommyDS `hashdyn`/`hashlin` | `get(&K) -> Option[&V]`, `insert(K, V) -> Option[V]`, `remove(&K) -> Option[V]`, `iter()` views | O(1) expected; delete O(cluster), no allocation |
| `BTreeMap[K, V]` / `BTreeSet[T]` | c-algorithms RB/AVL, M*LIB B+ tree | as above plus `first`/`last`, `range(&K, &K)`, ordered `iter()` | O(log n) all ops |
| `Heap[T]` | c-algorithms binary heap, STC `pqueue` | `push(T)`, `pop() -> Option[T]`, `peek() -> Option[&T]` | O(log n) push/pop, O(1) peek |
| `Deque[T]` | STC `deque` | `push_front/back(T)`, `pop_front/back() -> Option[T]`, `get(i) -> &T` | O(1) amortized ends, O(1) index |
| `BitSet` | STC `cbits` | `set/clear/test`, `count`, `iter()` | O(1) bit ops, O(n/64) count |
| `Vec[T].sort`, `sort_by`, `binary_search`, `lower_bound` | STC algorithms (shape set), byte engine | in-place, deterministic, stable variant for `sort_by` | O(n log n), O(log n) |
| `Trie` | c-algorithms trie, TommyDS `trie` | `insert(&str, V)`, `get(&str)`, prefix iteration | O(key length) |
| `SlotMap[T]` (native) | `rt_core` + FIFO free list (#936) | unchanged | O(1) insert/remove/lookup |

Each row gets its complexity fixture in the battery and its drop-audit
cells; the engine column is decided by the benchmark table, not by this
document.

## Phases and gates

**Phase 0 — measure first (small, immediate).**
The complexity-fixture lane and a stdlib inventory (`docs/stdlib_inventory.md`:
every structure and algorithm we need, its complexity contract, current
status). Winners cannot be chosen without the yardstick. SlotMap's native
free list (#936) lands here too. Gate: lane green on today's containers
with the known cliffs recorded as expected failures.

**Phase 1 — c-algorithms, whole.**
The first container corpus through the pipeline; non-macro C, so the
migrator work is the facade-shaped `void*` + callback idiom, not templates.
Facades: `BTreeMap`/`BTreeSet` (RB or AVL, retiring the sorted-Vec
implementation, #937), `Heap`/`PriorityQueue`, sorted array, trie; the hash
table as the first alternate engine to benchmark against `rt_core`'s.
Gate: upstream `test/` passes under With; facades' complexity fixtures
green; drop audit green; #937 closed.

**Phase 2 — TommyDS, whole.**
Performance engines: `hashdyn`/`hashlin` benchmarked against the Phase 1
hash table and `rt_core`'s (#939 becomes "which engine wins", not a patch),
tries, blocked arrays. The facade design item is node ownership (above).
Gate: `check.c` passes under With; benchmark table recorded; HashMap
engine decision made with numbers.

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
covers. Both keep the migrator raw; both are decided by benchmark and
recorded next to the facade.
Facades: `Deque`, `BitSet` (`cbits` is not generic — raw fits it
directly), `Vec.sort`/`sort_by`/`binary_search`/`lower_bound` (#940),
sequence algorithms; `VecIntoIter`'s cursor (#938) either from STC's vec
iteration or native, by benchmark. Gate: STC's own `tests/` pass under
With with no corpus-specific migrator code; #940 and #938 closed.

**Phase 4 — M*LIB `m-bptree.h`, surgical.**
Only the B+ tree, benchmarked against the Phase 1 tree for the ordered-map
engine; the facade keeps whichever wins. Gate: M*LIB's bptree tests pass;
decision recorded.

Order is fixed by risk: 1 validates the whole-corpus pipeline on a
container library, 2 adds the performance yardstick, 3 is the campaign, 4
is a bounded extra.

## What "done" means

Each phase is done only when: the corpus migrates from its pin with zero
hand edits; its upstream tests pass under With; every migrator change made
for it is general (no corpus name in `with migrate`); the facades it feeds
have complexity fixtures and drop-audit cells; the engine choice is
recorded with numbers; and the issues it retires are closed with evidence.
A green build with a silently mishandled corpus is 0% done (§"Good enough
for now").

## Open questions for Eric

1. (Ruled: D37 — the migrator is raw; generic facades over templated
   engines choose between a declared instantiation set and a byte-engine
   in Phase 3, by benchmark.)
2. Where the corpora live and whether all of them build in every battery
   (proposal: yes, in a `corpora` lane — the coverage is the point; cost is
   build time, measured in Phase 1).
3. Whether Phase 0's inventory should also rule on names and surfaces now
   (`Heap` vs `PriorityQueue`, `BitSet` API), or leave that to each facade
   PR.
