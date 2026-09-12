# Algorithms and data structures inventory

Phase 0 inventory for [the sourcing plan](stdlib_sourcing_plan.md). This records
implementation facts and the plan's complexity targets; it does not rule on new
public names or signatures. Costs exclude user comparators, hashing, cloning,
and destructors unless stated. Container storage is proportional to reserved
capacity, which can retain a historical high-water mark after removals. SlotMap
cleanup scans capacity; permanently retired generations also retain their slot.

## Existing containers

| Surface | Current implementation | Required cost | Gap / next source |
|---|---|---|---|
| `Vec[T]` | Contiguous runtime buffer, geometric growth | Amortized O(1) push/pop; O(1) access; O(n) arbitrary insertion/removal | Retain native storage and D27 views |
| `VecIter[T]` | Borrowed contiguous traversal | O(1) per next, O(n) full traversal | Retain; iteration must preserve element views |
| `VecIntoIter[T]` | `next()` calls `remove(0)` | O(1) amortized per next; O(n) full consumption, including partial-iterator cleanup | **#938:** each next shifts the tail; O(n²) full consumption |
| `HashMap[K, V]` | Runtime open addressing and linear probing | Expected O(1) lookup/insert; removal O(cluster length), with no allocation | **#939:** removal allocates two temporary buffers for each displaced entry; compare migrated hash engines in Phase 2 |
| `HashSet[T]` | Same runtime hash engine | Same bounds as HashMap | Shares #939 |
| `BTreeMap[K, V]` | Sorted `Vec[(K,V)]`; linear lookup | O(log n) lookup, insert, remove; O(n) ordered traversal | **#937:** lookup/ascending insert O(n); middle insert drains the vector with repeated `remove(0)`, O(n²) per insertion and O(n³) descending fill |
| `BTreeSet[T]` | Sorted Vec; linear search and element shifting | O(log n) lookup, insert, remove; O(n) ordered traversal | **#937:** linear operations; O(n²) bulk fill |
| `SlotMap[T]`, `Handle[T]` | Runtime indexed slots and generations | Amortized O(1) insert; O(1) remove/lookup; preserve valid handles across growth | **#936:** Phase 0 replaces insertion's occupancy scan with a FIFO free list; no C engine |
| `str` and string views | Native runtime representation and operations | O(1) byte length/access/view creation; O(n) copying and concatenation | Retain native implementation; not replaced with STC `cstr` |

Existing definitions are in `lib/std/collections.w`; storage engines are in
`rt/rt_core.w`. The keyed-map ownership contract remains D22: lookup returns a
view, removal transfers ownership. The inventory does not treat Copy elements
as an exception to that contract.

## Required additions

| Structure or algorithm family | Complexity target | Current status / sourcing gate |
|---|---|---|
| Ordered-map/set `first`, `last`, bounded ranges | O(log n + k) range query, O(k) traversal | Ordered-tree facade work; current `keys`/`values`/`items` allocate snapshots |
| Heap / priority queue | O(log n) push/pop, O(1) peek | Missing facade; c-algorithms heap, then STC pqueue comparison |
| Deque / queue | Amortized O(1) operations at either end, O(1) indexed access | Missing facade; STC deque/queue, with generic byte-engine fallback settled at facade design |
| Stack | Amortized O(1) push/pop | Vec already supplies the storage behavior; no separate public type ruled |
| Bit set | O(1) bit operations; O(n/word-size) count and bulk set operations | Missing facade; STC cbits |
| Trie / prefix index | O(key length) lookup/update; output-sensitive prefix traversal | Missing facade; c-algorithms and TommyDS tries |
| Sorted array | O(log n) search, O(n) insertion/removal | Missing facade; c-algorithms sorted array; distinct from the tree complexity contract |
| Sorting / comparator sorting / stable sorting | O(n log n) worst-case comparison growth; stable variant preserves equal-key order | **#940:** no generic sort surface; STC algorithm layer and byte-engine candidates |
| Binary search / lower and upper bounds | O(log n) comparisons | Missing generic surface; same sorted-range facade |
| Reverse / rotate / partition / shuffle | O(n) element visits; shuffle has an explicit random source | Algorithm inventory; STC breadth, public surfaces still to be settled |
| Find / count / min / max / folds | O(n) traversal, O(1) auxiliary state for scalar reductions | Audit/adapt existing iterator conveniences when the algorithms facade lands; no engine decision yet |
| Graph traversal: BFS, DFS, topological order, components | O(V + E) | Native work; representation and public API not yet ruled |
| Shortest paths / spanning trees | Algorithm-specific: e.g. Dijkstra O((V + E) log V), Kruskal O(E log E) | Native work; choose applicable algorithms and preconditions before exposing APIs |
| Union-find | Amortized inverse-Ackermann union/find, O(n) initialization | Native work; public API not yet ruled |

These are target contracts, not claims that the proposed surface exists. Every
new facade must add correctness, complexity, and Drop coverage when implemented.

## Corpus scope and gate

| Corpus | Migration scope | First consumers |
|---|---|---|
| c-algorithms | Whole pinned corpus plus upstream tests | Ordered trees, heap, sorted array, trie; alternate hash engine |
| TommyDS | Whole pinned corpus plus `check.c` | Competing hashing, tries, stable node storage |
| STC | Whole pinned corpus, including the concrete macro instantiations used by its tests/examples | Deque, bit set, sorting/search, breadth and competing engines |
| M*LIB (P-p-H-d) | The plan's explicit surgical exception: `m-bptree.h` and its tests | B+ tree comparison |

Raw lists, blocked arrays, intrusive nodes, and alternate engines remain covered
by migrated upstream tests even when no public With facade selects them. Each
corpus follows the PCRE2/zlib pin → reference → raw migration → `.wo` → upstream
tests pattern. Phase 0 chooses no winning C engine and performs no corpus migration.

## Measurement interpretation

The complexity lane checks results, preserved/stale handles, ascending and
descending insertion, lookups, removals, and consuming traversal. Runtime growth
is measured inside an optimized native executable, excluding compilation and
process startup. Repeated small/large measurements use broad bounds; they detect
the known polynomial cliffs, not a mathematical asymptotic proof.

Known failures are tied to #937, #938, and #939. A crash or wrong result fails
the lane; it is never accepted as a complexity failure. Unexpected passes require
updating the expectation with the fix's evidence. Hash deletion's no-allocation
contract needs an allocation trace because runtime growth alone cannot prove it.
