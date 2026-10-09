# 13.3 Collection Operations (Standard Library)

The collection surface is one integrated design at three altitudes:
literals (§4.3c) when the elements are known, comprehensions (§13.6)
when iteration has a shape, and these pipeline operations for
everything else. The operation set is deliberately lodash-grade —
grouping, chunking, deduplication, and partitioning are standard
vocabulary, not exotica — and everything funnels through the same
`collect[C]` targets the literals and comprehensions use.

**Transformations** (lazy, produce iterators):

| Operation | Description |
|-----------|-------------|
| `map(fn(T) -> U)` | Transform each element |
| `filter(fn(&T) -> bool)` | Keep matching elements |
| `filter_map(fn(T) -> Option[U])` | Transform + filter |
| `flat_map(fn(T) -> Iter[U])` | Map then flatten |
| `flatten()` | Flatten nested iterators |
| `take(n)` | First n elements |
| `drop(n)` | Skip first n |
| `take_while(fn(&T) -> bool)` | Take while predicate holds |
| `drop_while(fn(&T) -> bool)` | Skip while predicate holds |
| `zip(Iter[U])` | Pair from two iterators |
| `enumerate()` | Attach index |
| `chain(Iter[T])` | Concatenate |
| `peekable()` | Allow lookahead |
| `chunks(n)` | Fixed-size groups |
| `windows(n)` | Sliding window |
| `dedup()` | Remove consecutive duplicates |
| `unique()` | Remove all duplicates |
| `intersperse(sep)` | Insert separator |
| `scan(init, fn(S, T) -> (S, U))` | Stateful map |
| `step_by(n)` | Every nth element |
| `zip_with(Iter[U], fn(T, U) -> V)` | Zip and transform in one step |

**Consumers** (eager, produce final value):

| Operation | Description |
|-----------|-------------|
| `collect[C]()` | Build a collection |
| `reduce(fn(T, T) -> T)` | Reduce with first element as initial |
| `fold(init, fn(U, T) -> U)` | Fold with explicit initial |
| `sum()` / `product()` | Arithmetic aggregation |
| `count()` | Count elements |
| `min()` / `max()` | Extremes |
| `min_by(cmp)` / `max_by(cmp)` | By custom comparison |
| `find(fn(&T) -> bool)` | First match |
| `position(fn(&T) -> bool)` | Index of first match |
| `any(pred)` / `all(pred)` / `none(pred)` | Boolean tests |
| `for_each(fn(T))` | Side effect per element |
| `join(sep)` | Join as string |
| `sorted()` / `sorted_by(cmp)` | Collect and sort |
| `group_by(fn(&T) -> K)` | Group into buckets |
| `partition(fn(&T) -> bool)` | Split by predicate |
| `unzip()` | Separate pairs |

**Standalone iterator constructors** (not methods on existing iterators):

| Constructor | Description |
|-------------|-------------|
| `Iter.empty()` | Empty iterator |
| `Iter.once(value)` | Single element |
| `Iter.repeat(value)` | Infinite repetition |
| `Iter.unfold(init, fn(S) -> Option[(T, S)])` | Generate from state |
| `Iter.from_fn(fn() -> Option[T])` | Generate from closure |

**Examples:**
```
let total = numbers.iter() |> fold(0, (acc, x) => acc + x)

let words = lines.iter()
    |> flat_map(line => line.split(' '))
    |> collect[List[String]]()

let (adults, minors) = people.iter()
    |> partition(p => p.age >= 18)

// zip_with: combine two iterators with a function
let distances = xs.iter()
    |> zip_with(ys.iter(), (x, y) => (x - y).abs())
    |> collect[List]()

// unfold: generate sequence from state
let powers_of_2 = Iter.unfold(1, n => Some((n, n * 2)))
    |> take(10) |> collect[List]()
// [1, 2, 4, 8, 16, 32, 64, 128, 256, 512]

let report = transactions.iter()
    |> filter(t => t.amount > 100.0)
    |> sorted_by((a, b) => b.date.cmp(a.date))
    |> take(10)
    |> map(t => "{t.date}: ${t.amount}")
    |> join("\n")
```

**Sequence ends (D117).** On a `List`, a slice or a fixed array:

| Operation | Description |
|-----------|-------------|
| `first()` | `Option` of the first element |
| `last()` | `Option` of the last element |
| `rest()` | The elements after the first; empty for an empty sequence |

`xs.first()` and `xs.rest()` are the expression forms of `[first, ..rest]`
(§9.7), with its modes, selected by the receiver's syntax (§9.5, D117). On a
place, `first()` and `last()` give `Option[&T]` and `rest()` a `[]T` view. On
an owned receiver (a temporary, or `move xs`), `first()` and `last()` give
`Option[T]`, and `rest()` gives the owned remainder: for a `List`, a `List[T]`
sharing its buffer; for a fixed array, `[T; N-1]`. `rest()` is O(1) on a
place and on an owned `List`. Indexing an empty sequence (`xs[0]`) panics;
`first()` answers `None`.

**Lookup observes; removal transfers (D22).**

Every owning keyed map in the standard library, including `HashMap[K, V]`
and `BTreeMap[K, V]`, has one uniform lookup contract:

| Method | Signature | Ownership |
|--------|-----------|-----------|
| `get` | `(self: &Self, key: K) -> Option[&V]` | Borrows map-owned storage |
| `remove` | `(mut self: Self, key: K) -> Option[V]` | Transfers ownership out |

`get` returns `Option[&V]` for every `V`, including `Copy` values. Its return
type does not vary by generic instantiation. The returned view originates in
the map receiver, not in the transient key argument, and remains valid only
while that storage remains unmutated.

`remove` is the ownership-transfer operation. A successfully removed value is
independent of subsequent mutation or destruction of the map. A separately
named copying or cloning convenience may produce an owned value, but `get`
itself never changes return shape according to whether `V` implements `Copy`.

`List`, string, array, and slice indexing or lookup APIs are not
restandardized by D22. The general rules of §3.8, §9.7, §10, and §21.1 apply
to their existing signatures exactly as written. Any change to those
signatures is a separate ruling, provisionally identified as a D23 candidate.
`SlotMap.get` already has the uniform `Option[&T]` contract specified by §6.2
and therefore participates in D22 without an API change.

**Insertion order and a seeded hash (D96).** A `HashMap` or `HashSet`
iterates in insertion order: an entry keeps the position of its first
insertion, an insert of a key already present replaces its value in place,
and a removal leaves the rest in order. The order is the same run to run
and host to host, because it depends on the order of insertions, not on
hash values. The hash is seeded once per process from the runtime's
randomness capability: it protects a map whose keys an adversary chooses
from degrading to quadratic time, and is otherwise unobservable; a
deterministic replay records the seed as it records any random value.

**Traversal observes; consuming iteration transfers (D44).**

Every owning keyed map in the standard library, including `HashMap[K, V]`
and `BTreeMap[K, V]`, has one uniform traversal contract:

| Method | Signature | Yields | Ownership |
|--------|-----------|--------|-----------|
| `iter` | `(self: &Self) -> MapIter[K, V]` | `(&K, &V)` | Borrows map-owned storage |
| `keys` | `(self: &Self) -> MapKeys[K, V]` | `&K` | Borrows map-owned storage |
| `values` | `(self: &Self) -> MapValues[K, V]` | `&V` | Borrows map-owned storage |
| `into_iter` | `(move self: Self) -> MapIntoIter[K, V]` | `(K, V)` | Consumes the map |
| `into_keys` | `(move self: Self) -> MapIntoKeys[K, V]` | `K` | Consumes the map; values are dropped |
| `into_values` | `(move self: Self) -> MapIntoValues[K, V]` | `V` | Consumes the map; keys are dropped |
| `drain` | `(mut self: Self) -> MapDrain[K, V]` | `(K, V)` | Transfers every entry out; the map remains, empty |

The observing iterators are concrete ephemeral structs (§13.1): usable in the
scope that made them, not stored, and they do not outlive the map. Their
views originate in the map receiver and remain valid only while that storage
remains unmutated, exactly as for `get`. Their signatures do not vary by
generic instantiation: `keys` yields `&K` for every `K`, including `Copy`
keys, which materialize under an owned demand by §3.8 (`let n: i32 = v`).

No traversal produces a second owner of a key or a value (§2.3). An element
leaves the map's ownership only through `remove`, `drain`, or a consuming
iterator.

An independent collection is spelled where it is wanted, because it
allocates and requires `Clone`:

```
let names = ages.keys() |> map(it.clone()) |> collect[List]()   // List[str], owned
let sorted = ages.keys() |> collect[List]() |> sorted()          // ephemeral List of views (§22.1 rule 7)
```

A typed binding does not collect: `let ks: List[K] = m.keys()` is a type
error, not a request to clone. §3.8 materializes `Copy` because a copy is
free; it never turns an annotation into an allocation.

**HashMap convenience methods:**

Beyond the standard iterator operations, `HashMap` provides
ergonomic mutation methods:

```
// Entry API (Rust-style)
worker_counts.entry(id).or_insert(0)

// Convenience: update with default and transform
worker_counts.update(id, 0, n => n + 1)
// equivalent to: entry(id).or_insert(0); *entry += 1

// Convenience: increment/decrement
worker_counts.increment(id)       // .update(id, 0, n => n + 1)
worker_counts.decrement(id)       // .update(id, 0, n => n - 1)

// Convenience: append to collection values
event_log.append(user_id, event)  // .entry(id).or_insert(List.new()).push(event)
```

These methods cover the most common HashMap mutation patterns
without requiring the entry API's verbose ceremony.
