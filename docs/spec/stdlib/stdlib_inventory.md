# Algorithms and data structures inventory

Phase 0 inventory for [the sourcing plan](stdlib_sourcing_plan.md). This records
implementation facts and the plan's complexity targets. Engine destinations
follow Eric's 2026-09-12 facade map; detailed new signatures remain facade work.
Costs exclude user comparators, hashing, cloning,
and destructors unless stated. Container storage is proportional to reserved
capacity, which can retain a historical high-water mark after removals. SlotMap
cleanup scans capacity; permanently retired generations also retain their slot.

## Existing containers

| Surface | Current implementation | Required cost | Gap / next source |
|---|---|---|---|
| `Vec[T]` | Contiguous runtime buffer, geometric growth | Amortized O(1) push/pop; O(1) access; O(n) arbitrary insertion/removal | STC `vec` in Phase 3, preserving language integration and D27 views |
| `VecIter[T]` | Borrowed contiguous traversal | O(1) per next, O(n) full traversal | Retain; iteration must preserve element views |
| `VecIntoIter[T]` | `next()` calls `remove(0)` | O(1) amortized per next; O(n) full consumption, including partial-iterator cleanup | **#938:** each next shifts the tail; O(n²) full consumption |
| `HashMap[K, V]` | Runtime open addressing and linear probing | Expected O(1) lookup/insert; removal O(cluster length), with no allocation | **#939:** removal allocates two temporary buffers for each displaced entry; selected replacement is STC `hmap` in Phase 3 |
| `HashSet[T]` | Same runtime hash engine | Same bounds as HashMap | Shares #939; STC `hset` in Phase 3 |
| `BTreeMap[K, V]` | Sorted `Vec[(K,V)]`; linear lookup | O(log n) lookup, insert, remove; O(n) ordered traversal | **#937:** lookup/ascending insert O(n); middle insert drains the vector with repeated `remove(0)`, O(n²) per insertion and O(n³) descending fill |
| `BTreeSet[T]` | Sorted Vec; linear search and element shifting | O(log n) lookup, insert, remove; O(n) ordered traversal | **#937:** linear operations; O(n²) bulk fill |
| `SlotMap[T]`, `Handle[T]` | Runtime indexed slots and generations | Amortized O(1) insert; O(1) remove/lookup; preserve valid handles across growth | **#936:** Phase 0 replaces insertion's occupancy scan with a FIFO free list; no C engine |
| `str` and string views | Native runtime representation and operations | O(1) byte length/access/view creation; O(n) copying and concatenation | Preserve With's public semantics; use STC `cstr` selectively where useful |

Existing definitions are in `lib/std/collections.w`; storage engines are in
`rt/rt_core.w`. The keyed-map ownership contract remains D22: lookup returns a
view, removal transfers ownership. The inventory does not treat Copy elements
as an exception to that contract.

## Required additions

| Structure or algorithm family | Complexity target | Current status / sourcing gate |
|---|---|---|
| Ordered-map/set `first`, `last`, bounded ranges | O(log n + k) range query, O(k) traversal | Ordered-tree facade work; current `keys`/`values`/`items` allocate snapshots |
| Binary heap / priority queue | O(log n) push/pop, O(1) peek | c-algorithms binary heap in Phase 1; STC `pqueue` supplies `PriorityQueue` in Phase 3 |
| Deque / queue | Amortized O(1) operations at either end, O(1) indexed access for deque | STC `deque`/`queue` in Phase 3 |
| Stack | Amortized O(1) push/pop | STC `stack`; may remain a thin sequence facade |
| Bit set | O(1) bit operations; O(n/word-size) count and bulk set operations | Missing facade; STC cbits |
| Trie / prefix index | O(key length) lookup/update; output-sensitive prefix traversal | c-algorithms `Trie` in Phase 1; TommyDS comparison engines |
| Sorted vector | O(log n) search, O(n) insertion/removal | c-algorithms sorted array supplies `SortedVec` in Phase 1 |
| Sorting / comparator sorting / stable sorting | O(n log n) worst-case comparison growth; stable variant preserves equal-key order | **#940:** STC algorithm layer in Phase 3; evaluate `stable_sort` separately before promising stability |
| Binary search / lower and upper bounds | O(log n) comparisons | Missing generic surface; same sorted-range facade |
| Reverse / rotate / partition / shuffle | O(n) element visits; shuffle has an explicit random source | Algorithm inventory; STC breadth, public surfaces still to be settled |
| Find / count / min / max / folds | O(n) traversal, O(1) auxiliary state for scalar reductions | STC algorithms where available and appropriate; audit/adapt existing iterator conveniences |
| Graph traversal: BFS, DFS, topological order, components | O(V + E) | Native work; representation and public API not yet ruled |
| Shortest paths / spanning trees | Algorithm-specific: e.g. Dijkstra O((V + E) log V), Kruskal O(E log E) | Native work; choose applicable algorithms and preconditions before exposing APIs |
| Union-find | Amortized inverse-Ackermann union/find, O(n) initialization | Native work; public API not yet ruled |

These are target contracts, not claims that the proposed surface exists. Every
new facade must add correctness, complexity, and Drop coverage when implemented.

## Corpus scope and gate

| Corpus | Migration scope | First consumers |
|---|---|---|
| c-algorithms | Whole pinned corpus plus upstream tests | Trie, SortedVec, binary heap; classical trees and hash comparison engines |
| TommyDS | Whole pinned corpus plus `check.c` | Specialized indexing, tries, stable node storage |
| STC | Whole pinned corpus, including the concrete macro instantiations used by its tests/examples | Everyday containers including Vec, HashMap/HashSet, OrderedMap/OrderedSet, PriorityQueue; algorithms and spans |
| M*LIB (P-p-H-d) | The plan's explicit surgical exception: `m-bptree.h` and its tests | BTreeMap/BTreeSet, retiring #937 in Phase 4 |

Raw lists, blocked arrays, intrusive nodes, and alternate engines remain covered
by migrated upstream tests even when no public With facade selects them. Each
corpus follows the PCRE2/zlib pin → reference → raw migration → `.wo` → upstream
tests pattern. Phase 0 performs no corpus migration; the selected destinations
are implemented in their respective later phases.

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
