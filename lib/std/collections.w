// std.collections — collection type surface imported by the prelude.
//
// Keep this module intentionally minimal for selfhost compatibility.
// The compiler still owns the lowering/runtime behavior for these
// collection types; this module provides the user-facing names so they
// resolve through normal imports instead of hardcoded sema allowlists.

use std.option

/// A growable array. Create with `Vec.new()`, add with `.push()`,
/// read with `.get()`. Supports iteration via `.iter()`.
pub type Vec[T]  {
    ptr: *const T,
    len: i64,
    cap: i64,
    elem_size: i64,
}

/// Clone for Vec[T]: produces a deep copy by cloning each element.
impl[T: Clone] Clone for Vec[T]:
    fn clone() -> Self:
        var out: Vec[T] = Vec.new()
        var index: i64 = 0
        while index < self.len():
            let item = self[index]
            comptime if T.is_copy():
                out.push(item)
            else:
                out.push(item.clone())
            index = index + 1
        out

/// An unordered key-value map. Create with `HashMap.new()`,
/// insert with `.insert(key, val)`, read with `.get(key)`.
pub type HashMap[K, V]  {
    ptr: *const i8,
}

/// An unordered set of unique values. Create with `HashSet.new()`.
pub type HashSet[T]  {
    ptr: *const i8,
}

/// Ordered key-value map. This first stdlib implementation uses Vec-backed
/// storage but preserves BTree semantics without using HashMap storage.
pub type BTreeMap[K, V] {
    entries: Vec[(K, V)],
}

/// Ordered set of unique values. Backed by a sorted Vec.
pub type BTreeSet[T] {
    values: Vec[T],
}

pub fn BTreeMap.new[K, V]() -> BTreeMap[K, V]:
    BTreeMap { entries: Vec.new() }

impl[K: Ord, V] BTreeMap[K, V]:
    pub fn len() -> i64:
        self.entries.len()

impl[K, V] BTreeMap[K, V]:
    pub fn is_empty() -> bool:
        self.entries.len() == 0

    pub mut fn clear() -> Unit:
        self.entries.clear()

impl[K, V] BTreeMap[K, V]:
    fn key_at(index: i64) -> &K: &self.entries[index].0

    fn value_at(index: i64) -> &V: &self.entries[index].1

impl[K: Ord, V] BTreeMap[K, V]:
    // #773: pure read — takes &K so both view-holding callers (get/contains)
    // and owning callers (remove, whose D22 contract keeps `key: K`) borrow.
    fn last_index_of(key: &K) -> i64:
        var found = -1
        var i = 0
        while i < self.entries.len():
            let existing = self.key_at(i)
            if not (existing < key) and not (existing > key):
                found = i
            i = i + 1
        found

    pub fn contains(key: &K) -> bool:
        var i = 0
        while i < self.entries.len():
            let existing = self.key_at(i)
            if not (existing < key) and not (existing > key):
                return true
            i = i + 1
        false

    pub fn get(key: &K) -> Option[&V]:
        let idx = self.last_index_of(key)
        if idx < 0:
            return None
        Some(self.value_at(idx))

    pub mut fn insert(key: K, value: V) -> Unit:
        var i = 0
        while i < self.entries.len():
            let existing = self.key_at(i)
            if not (existing < key) and not (existing > key):
                with self.entries.slot(i) as mut slot:
                    slot.set((key, value))
                return
            if existing > key:
                let reordered: Vec[(K, V)] = Vec.new()
                var old_index = 0
                while old_index < i:
                    reordered.push(self.entries.remove(0))
                    old_index = old_index + 1
                reordered.push((key, value))
                while self.entries.len() > 0:
                    reordered.push(self.entries.remove(0))
                self.entries = reordered
                return
            i = i + 1
        self.entries.push((key, value))

    pub mut fn remove(key: K) -> Option[V]:
        let idx = self.last_index_of(key)
        if idx < 0:
            return None
        let (_, removed_value) = self.entries.remove(idx)
        Some(removed_value)

    // D44: traversal observes. Each yields views into the entries.
    @[iter_of_self]
    pub fn iter() -> MapIter[K, V]: MapIter { source: .Tree(self), at: 0 }

    @[iter_of_self]
    pub fn keys() -> MapKeys[K, V]: MapKeys { source: .Tree(self), at: 0 }

    @[iter_of_self]
    pub fn values() -> MapValues[K, V]: MapValues { source: .Tree(self), at: 0 }

// §15.4.7 / D61: the `:?` forms of the maps. The compiler calls these for
// every map an f-string formats with `:?`, at any depth; `{k:?}` and `{v:?}`
// are the same recursive formatter, so a map formats the same everywhere.

// `{key: value, key: value}` in key order.
impl[K: Ord, V] BTreeMap[K, V]:
    fn debug_form() -> str:
        let parts: Vec[str] = Vec.with_capacity(self.entries.len())
        var i: i64 = 0
        while i < self.entries.len():
            parts.push(f"{self.key_at(i):?}: {self.value_at(i):?}")
            i = i + 1
        "{" ++ parts.join(", ") ++ "}"

// `{key: value, key: value}` ordered by the Debug text of the keys: a key
// need not be Ord, and the hash order is seeded — a snapshot or a fixpoint
// would differ run to run. Each key and value is formatted once; the order
// is a stable merge sort of indices, so equal key text falls back to the
// value text and the output is byte-identical for equal maps.
impl[K, V] HashMap[K, V]:
    fn debug_form() -> str:
        let keys: Vec[str] = Vec.with_capacity(self.len())
        let values: Vec[str] = Vec.with_capacity(self.len())
        for (key, value) in self:
            keys.push(f"{key:?}")
            values.push(f"{value:?}")
        let order = debug_entry_order(&keys, &values)
        let parts: Vec[str] = Vec.with_capacity(order.len())
        for i in order:
            parts.push(f"{keys[i]}: {values[i]}")
        "{" ++ parts.join(", ") ++ "}"

// `{elem, elem}` ordered by the Debug text of the elements, for the same
// reason as a HashMap's keys. The set has no traversal of its own: the
// compiler walks its table, formats each element with `:?`, and hands the
// texts here (#1564).
impl[T] HashSet[T]:
    fn debug_form_of(texts: &Vec[str]) -> str:
        let parts: Vec[str] = Vec.with_capacity(texts.len())
        for i in debug_entry_order(texts, texts):
            parts.push(texts[i].clone())
        "{" ++ parts.join(", ") ++ "}"

fn debug_entry_before(keys: &Vec[str], values: &Vec[str], a: i64, b: i64) -> bool:
    keys[a] < keys[b] or (keys[a] == keys[b] and values[a] < values[b])

// Bottom-up merge sort of 0..n by (key text, value text): n log n
// comparisons, one scratch buffer, no allocation per comparison.
fn debug_entry_order(keys: &Vec[str], values: &Vec[str]) -> Vec[i64]:
    let n = keys.len()
    let order: Vec[i64] = Vec.with_capacity(n)
    let scratch: Vec[i64] = Vec.with_capacity(n)
    for i in 0..n:
        order.push(i)
        scratch.push(i)
    var width: i64 = 1
    while width < n:
        var lo: i64 = 0
        while lo < n:
            let mid = if lo + width < n: lo + width else: n
            let hi = if lo + 2 * width < n: lo + 2 * width else: n
            var a = lo
            var b = mid
            for k in lo..hi:
                if a < mid and (b >= hi or not debug_entry_before(keys, values, order[b], order[a])):
                    scratch[k] = order[a]
                    a = a + 1
                else:
                    scratch[k] = order[b]
                    b = b + 1
            for k in lo..hi:
                order[k] = scratch[k]
            lo = hi
        width = width * 2
    order

pub fn BTreeSet.new[T]() -> BTreeSet[T]:
    BTreeSet { values: Vec.new() }

impl[T: Ord] BTreeSet[T]:
    pub fn len() -> i64:
        self.values.len()

impl[T] BTreeSet[T]:
    pub fn is_empty() -> bool:
        self.values.len() == 0

    pub mut fn clear() -> Unit:
        self.values.clear()

impl[T: Ord] BTreeSet[T]:
    fn index_of(value: T) -> i64:
        var i = 0
        while i < self.values.len():
            let existing = self.values[i]
            if not (existing < value) and not (existing > value):
                return i
            i = i + 1
        -1

    pub fn contains(value: &T) -> bool:
        var i = 0
        while i < self.values.len():
            let existing = self.values[i]
            if not (existing < value) and not (existing > value):
                return true
            i = i + 1
        false

    pub mut fn insert(value: T) -> Unit:
        var i = 0
        while i < self.values.len():
            let existing = self.values[i]
            if not (existing < value) and not (existing > value):
                with self.values.slot(i) as mut slot:
                    slot.set(value)
                return
            if existing > value:
                self.values.push(value)
                var j = self.values.len() - 1
                while j > i:
                    // Typed lets snapshot the elements: a view of slot j-1
                    // would observe the first set() and duplicate it (the
                    // §3.2 view-liveness hazard E3 will reject).
                    let left: T = self.values[j - 1]
                    let right: T = self.values[j]
                    with self.values.slot(j - 1) as mut left_slot:
                        left_slot.set(right)
                    with self.values.slot(j) as mut right_slot:
                        right_slot.set(left)
                    j = j - 1
                return
            i = i + 1
        self.values.push(value)

    pub mut fn remove(value: T) -> bool:
        let idx = self.index_of(value)
        if idx < 0:
            return false
        var i = 0
        while i < self.values.len():
            let existing = self.values[i]
            if not (existing < value) and not (existing > value):
                let _ = self.values.remove(i)
            else:
                i = i + 1
        true

    pub fn items() -> Vec[T]:
        let out: Vec[T] = Vec.new()
        var value_i = 0
        while value_i < self.values.len():
            let value = self.values[value_i]
            out.push(value.clone())
            value_i = value_i + 1
        out

impl[T: Ord] BTreeSet[T]:
    pub fn union(other: &BTreeSet[T]) -> BTreeSet[T]:
        let out: BTreeSet[T] = BTreeSet[T].new()
        var self_i = 0
        while self_i < self.values.len():
            let value: T = self.values[self_i]
            out.insert(value)
            self_i = self_i + 1
        var other_i = 0
        while other_i < other.values.len():
            let value2: T = other.values[other_i]
            out.insert(value2)
            other_i = other_i + 1
        out

impl[T: Ord] BTreeSet[T]:
    pub fn intersection(other: &BTreeSet[T]) -> BTreeSet[T]:
        let out: BTreeSet[T] = BTreeSet[T].new()
        var self_i = 0
        while self_i < self.values.len():
            let value: T = self.values[self_i]
            if other.contains(value):
                out.insert(value)
            self_i = self_i + 1
        out

    pub fn difference(other: &BTreeSet[T]) -> BTreeSet[T]:
        let out: BTreeSet[T] = BTreeSet[T].new()
        var self_i = 0
        while self_i < self.values.len():
            let value: T = self.values[self_i]
            if not other.contains(value):
                out.insert(value)
            self_i = self_i + 1
        out

impl[T: Ord] Iterable[T] for BTreeSet[T]:
    fn iter() -> VecIter[T]:
        self.values.iter()

/// Type-safe generational handle into a SlotMap[T].
/// Handles are Copy and carry their owner element type at compile time, so a
/// Handle[Texture] cannot be used with a SlotMap[Mesh].
pub type Handle[T] {
    pub index: u32,
    pub generation: u32,
}

impl[T] Copy for Handle[T]

/// Generational dense-ish storage for long-lived relationships.
/// Runtime storage is compiler-backed like Vec and HashMap.
pub type SlotMap[T] {
    ptr: *const i8,
}

/// Scoped mutable slot handle returned by SlotMap.slot/get_disjoint.
/// Use `.get()` / `.set(value)` inside the `with` block, matching VecSlot.
pub type SlotMapSlot[T] ephemeral {
    map_ptr: i64,
    index: u32,
    generation: u32,
}

/// Memory ordering for atomic operations.
pub enum Order: i32:
    Relaxed = 0
    Acquire = 1
    Release = 2
    AcqRel = 3
    SeqCst = 4

impl Copy for Order

/// Atomic memory fence. Enforces ordering without an associated operation.
pub fn fence(order: Order) -> Unit:
    // Compiler intrinsic — body is replaced by MIR_INTRINSIC_ATOMIC_FENCE
    0

/// Lock-free atomic operations on integer types.
/// Create with `Atomic.new(0)`, read with `.load(.acquire)`,
/// write with `.store(val, .release)`.
pub type Atomic[T]  {
    val: T,
}

// ── Scoped access ────────────────────────────────────────────────

/// Scoped handle to a single Vec element (docs/mut.md Rev 8 §10).
/// Obtain via `vec.slot(index)`. Use with `with`:
///   with xs.slot(i) as mut s:
///       let v = s.get()
///       s.set(v + 1)
pub type VecSlot[T] ephemeral { data_ptr: i64, index: i64 }

/// Iterator yielding VecSlot[T] handles for in-place element mutation (§19.5).
/// Obtain via `vec.iter_place()`. Each `.next()` returns `Option[VecSlot[T]]`.
pub type VecIterPlace[T] ephemeral { data_ptr: i64, len: i64, idx: i64 }

/// Scoped handle to a HashMap entry (docs/mut.md Rev 8 §10).
/// Obtain via `map.entry(key)`. Use with `with`:
///   with map.entry(k) as mut e:
///       e.or_insert(default)
pub type HashMapEntry[K, V] ephemeral { map_ptr: i64, key: K }

// ── Iterators ─────────────────────────────────────────────────────

/// Iterator over Vec[T]. Obtain via `vec.iter()`.
/// Call `.next()` to get `Option[T]` — `Some(val)` or `None`.
pub type VecIter[T] ephemeral { data_ptr: i64, len: i64, idx: i64 }

/// Borrow-iteration capability for allocation-backed collection types
/// (D33 naming: formerly misnamed `IntoIter`).
/// §13.2: the borrow an iterator registers on its receiver is SHARED, so
/// constructing one only reads the collection — a `&Vec` parameter iterates.
/// (A trait method's receiver is explicit: plain `fn` in a trait declares a
/// static method, per the parser's trait-impl receiver rule.)
pub trait Iterable[T]:
    fn iter(self: &Self) -> VecIter[T]

// Iterable for Vec — explicit borrow-iteration trait dispatch over
// Vec-backed collections.
impl[T] Iterable[T] for Vec[T]:
    fn iter() -> VecIter[T]: self.iter()

/// Each element with its index (§13.5): `for (i, x) in xs.enumerate():`.
impl[T] Vec[T]:
    // D100 (§18.3): Vec's fields are private to std. The buffer's address,
    // for a C call or a runtime helper; reading through it is `unsafe`.
    pub fn as_ptr() -> *const T: self.ptr
    pub fn as_mut_ptr() -> *mut T: self.ptr as *mut T
    // How many elements the buffer holds before it grows.
    pub fn capacity() -> i64: self.cap

    // The result type is the body's: over elements that own something
    // `iter()` yields views (#2145), so the pairs hold `&T`.
    fn enumerate(): self.iter() |> enumerate()

impl[T] Vec[T]:
    /// Exchanges elements `i` and `j` in place. Their bytes move between the
    /// two slots; nothing is copied or dropped (§2.3: transport is not
    /// duplication). Panics when either index is out of range.
    pub mut fn swap(i: i64, j: i64):
        if i < 0 or j < 0 or i >= self.len or j >= self.len:
            panic(f"Vec.swap: index out of range (len {self.len}, {i} and {j})")
        if i == j: return
        let a = self.ptr as i64 + i * self.elem_size
        let b = self.ptr as i64 + j * self.elem_size
        var k = 0
        while k < self.elem_size:
            let pa = (a + k) as *mut u8
            let pb = (b + k) as *mut u8
            let byte = unsafe *pa
            unsafe *pa = unsafe *pb
            unsafe *pb = byte
            k = k + 1

impl[T: Ord] Vec[T]:
    /// Sorts the elements in ascending order, in place: heapsort, O(n log n),
    /// no allocation; elements move by `swap`, never by copy. Not stable.
    pub mut fn sort():
        let n = self.len()
        var start = n / 2
        while start > 0:
            start = start - 1
            self.sift_down(start, n)
        var end = n
        while end > 1:
            end = end - 1
            self.swap(0, end)
            self.sift_down(0, end)

    // Restores the max-heap below `root` within the first `end` elements.
    mut fn sift_down(root: i64, end: i64):
        var parent = root
        while true:
            var child = 2 * parent + 1
            if child >= end: return
            if child + 1 < end and self[child] < self[child + 1]: child = child + 1
            if not (self[parent] < self[child]): return
            self.swap(parent, child)
            parent = child

/// Consuming iterator over Vec[T] (§13, D33). Obtain via `vec.into_iter()`:
/// the Vec moves into the iterator and each `.next()` moves one element out.
/// Dropping the iterator early (break, `?`, return) releases the un-yielded
/// tail and the buffer through the owned Vec's ordinary drop.
pub type VecIntoIter[T] { vec: Vec[T] }

/// Consuming-iteration capability (§13, D33): the collection moves in,
/// elements move out. The loop-shaped `remove` — access observes,
/// transfer is explicit (D27).
pub trait IntoIter[T]:
    move fn into_iter() -> VecIntoIter[T]

impl[T] IntoIter[T] for Vec[T]:
    move fn into_iter() -> VecIntoIter[T]: VecIntoIter { vec: self }

impl[T] Iter[T] for VecIntoIter[T]:
    // remove(0) is D27's proven element transfer; the memmove-per-next
    // cost stands until a front-cursor variant earns its unsafe.
    mut fn next() -> Option[T]:
        if self.vec.len() == 0: return None
        Some(self.vec.remove(0))

// ── Map traversal (D44) ───────────────────────────────────────────
// The observing traversals of a keyed map: concrete ephemeral structs over a
// view of the map, whose items are views into its storage. Nothing is copied
// out (§2.3). A HashMap or HashSet is walked through its entry slots in
// insertion order (D96), skipping removed entries; a BTreeMap through its
// key-ordered entries.

enum MapSource[K, V] ephemeral:
    Hash(&HashMap[K, V])
    Tree(&BTreeMap[K, V])

impl[K, V] MapSource[K, V]:
    // The first live position at or after `at`, or -1 at the end.
    fn live_from(at: i64) -> i64:
        match self:
            .Hash(m) =>
                var slot = at
                while slot < m.slot_count():
                    if m.slot_live(slot): return slot
                    slot = slot + 1
                -1
            .Tree(t) => if at < t.entries.len(): at else: -1

    fn key_at(at: i64) -> &K:
        match self:
            .Hash(m) => m.slot_key(at)
            .Tree(t) => t.key_at(at)

    fn value_at(at: i64) -> &V:
        match self:
            .Hash(m) => m.slot_value(at)
            .Tree(t) => t.value_at(at)

/// `map.iter()`, and what `for (k, v) in map` walks: each entry as views.
pub type MapIter[K, V] ephemeral { source: MapSource[K, V], at: i64 }

/// `map.keys()`: each key as a view.
pub type MapKeys[K, V] ephemeral { source: MapSource[K, V], at: i64 }

/// `map.values()`: each value as a view.
pub type MapValues[K, V] ephemeral { source: MapSource[K, V], at: i64 }

impl[K, V] Iter[(&K, &V)] for MapIter[K, V]:
    mut fn next() -> Option[(&K, &V)]:
        let slot = self.source.live_from(self.at)
        if slot < 0: return None
        self.at = slot + 1
        Some((self.source.key_at(slot), self.source.value_at(slot)))

impl[K, V] Iter[&K] for MapKeys[K, V]:
    mut fn next() -> Option[&K]:
        let slot = self.source.live_from(self.at)
        if slot < 0: return None
        self.at = slot + 1
        Some(self.source.key_at(slot))

impl[K, V] Iter[&V] for MapValues[K, V]:
    mut fn next() -> Option[&V]:
        let slot = self.source.live_from(self.at)
        if slot < 0: return None
        self.at = slot + 1
        Some(self.source.value_at(slot))

impl[K, V] HashMap[K, V]:
    @[iter_of_self]
    pub fn iter() -> MapIter[K, V]: MapIter { source: .Hash(self), at: 0 }

    @[iter_of_self]
    pub fn keys() -> MapKeys[K, V]: MapKeys { source: .Hash(self), at: 0 }

    @[iter_of_self]
    pub fn values() -> MapValues[K, V]: MapValues { source: .Hash(self), at: 0 }

// The consuming traversals (D44): each entry moves out of the map once.
// The entries move out together, last first, so each step pops the next in
// the map's order (insertion order for a HashMap, key order for a BTreeMap);
// the ones never yielded drop with the iterator.

/// `map.into_iter()`: each entry, moved out; the map is consumed.
pub type MapIntoIter[K, V] { entries: Vec[(K, V)] }

/// `map.into_keys()`: each key, moved out; the values are dropped.
pub type MapIntoKeys[K, V] { entries: MapIntoIter[K, V] }

/// `map.into_values()`: each value, moved out; the keys are dropped.
pub type MapIntoValues[K, V] { entries: MapIntoIter[K, V] }

/// `map.drain()`: each entry, moved out; the map remains, empty.
pub type MapDrain[K, V] { entries: MapIntoIter[K, V] }

impl[K, V] Iter[(K, V)] for MapIntoIter[K, V]:
    mut fn next() -> Option[(K, V)]: self.entries.pop()

impl[K, V] Iter[K] for MapIntoKeys[K, V]:
    mut fn next() -> Option[K]:
        match self.entries.next():
            Some((key, _)) => Some(key)
            None => None

impl[K, V] Iter[V] for MapIntoValues[K, V]:
    mut fn next() -> Option[V]:
        match self.entries.next():
            Some((_, value)) => Some(value)
            None => None

impl[K, V] Iter[(K, V)] for MapDrain[K, V]:
    mut fn next() -> Option[(K, V)]: self.entries.next()

impl[K, V] HashMap[K, V]:
    // Every entry, moved out, last first; the table is left empty.
    mut fn take_reversed() -> MapIntoIter[K, V]:
        var reversed: Vec[(K, V)] = Vec.with_capacity(self.len())
        var slot = self.slot_count() - 1
        while slot >= 0:
            if self.slot_live(slot): reversed.push(self.slot_take(slot))
            slot = slot - 1
        self.clear()
        MapIntoIter { entries: reversed }

    pub move fn into_iter() -> MapIntoIter[K, V]:
        var map = self
        map.take_reversed()

    pub move fn into_keys() -> MapIntoKeys[K, V]: MapIntoKeys { entries: self.into_iter() }

    pub move fn into_values() -> MapIntoValues[K, V]: MapIntoValues { entries: self.into_iter() }

    pub mut fn drain() -> MapDrain[K, V]: MapDrain { entries: self.take_reversed() }

impl[K, V] BTreeMap[K, V]:
    // Every entry, moved out, last first; the map is left empty.
    mut fn take_reversed() -> MapIntoIter[K, V]:
        var reversed: Vec[(K, V)] = Vec.with_capacity(self.entries.len())
        while true:
            match self.entries.pop():
                Some(entry) => reversed.push(entry)
                None => break
        MapIntoIter { entries: reversed }

    pub move fn into_iter() -> MapIntoIter[K, V]:
        var map = self
        map.take_reversed()

    pub move fn into_keys() -> MapIntoKeys[K, V]: MapIntoKeys { entries: self.into_iter() }

    pub move fn into_values() -> MapIntoValues[K, V]: MapIntoValues { entries: self.into_iter() }

    pub mut fn drain() -> MapDrain[K, V]: MapDrain { entries: self.take_reversed() }

/// `set.iter()`, and what `for x in set` walks: each element as a view.
pub type SetIter[T] ephemeral { set: &HashSet[T], at: i64 }

impl[T] Iter[&T] for SetIter[T]:
    mut fn next() -> Option[&T]:
        while self.at < self.set.slot_count():
            let slot = self.at
            self.at = slot + 1
            if self.set.slot_live(slot): return Some(self.set.slot_key(slot))
        None

impl[T] HashSet[T]:
    @[iter_of_self]
    pub fn iter() -> SetIter[T]: SetIter { set: self, at: 0 }

/// Lazy iterator adapter produced by `.map(f)`.
pub type MappedIter[I, T, U] ephemeral { iter: I, f: fn(T) -> U }

/// Lazy iterator adapter produced by `.filter(pred)`.
pub type FilterIter[I, T] ephemeral { iter: I, pred: fn(T) -> bool }

/// Lazy iterator adapter produced by `.filter_map(f)`.
pub type FilterMapIter[I, T, U] ephemeral { iter: I, f: fn(T) -> Option[U] }

/// Lazy iterator adapter produced by `.take(n)`.
pub type TakeIter[I, T] ephemeral { iter: I, remaining: i64 }

/// Lazy iterator adapter produced by `.drop(n)`.
pub type DropIter[I, T] ephemeral { iter: I, remaining: i64 }

/// Lazy iterator adapter produced by `.take_while(pred)`.
pub type TakeWhileIter[I, T] ephemeral { iter: I, pred: fn(T) -> bool, done: bool }

/// Lazy iterator adapter produced by `.drop_while(pred)`.
pub type DropWhileIter[I, T] ephemeral { iter: I, pred: fn(T) -> bool, dropping: bool }

/// Lazy iterator adapter produced by `.zip(other)`.
pub type ZipIter[A, B, T, U] ephemeral { left: A, right: B }

/// Lazy iterator adapter produced by `.enumerate()`.
pub type EnumerateIter[I, T] ephemeral { iter: I, idx: i64 }

/// Lazy iterator adapter produced by `.chain(other)`.
pub type ChainIter[A, B, T] ephemeral { left: A, right: B, use_right: bool }

/// Lazy iterator adapter produced by `.zip_with(other, f)`.
pub type ZipWithIter[A, B, T, U, V] ephemeral { left: A, right: B, f: fn(T, U) -> V }

/// Lazy iterator adapter produced by `.step_by(n)`.
pub type StepByIter[I, T] ephemeral { iter: I, step: i64, first: bool }

/// Lazy iterator adapter produced by `.flat_map(f)`.
pub type FlatMapIter[I, C, J, T, U] ephemeral {
    iter: I,
    f: fn(T) -> C,
    current: J,
    has_current: bool,
}

impl[T] Iter[T] for VecIter[T]:
    mut fn next() -> Option[T]:
        self.next()

// #2152 (§13.1, §13.5): every adapter is an iterator, so a `for` steps
// through it. Each `next` is the adapter's own.
impl[I, T] Iter[T] for FilterIter[I, T]:
    mut fn next() -> Option[T]: self.next()

impl[I, T, U] Iter[U] for MappedIter[I, T, U]:
    mut fn next() -> Option[U]: self.next()

impl[I, T, U] Iter[U] for FilterMapIter[I, T, U]:
    mut fn next() -> Option[U]: self.next()

impl[I, T] Iter[T] for TakeIter[I, T]:
    mut fn next() -> Option[T]: self.next()

impl[I, T] Iter[T] for DropIter[I, T]:
    mut fn next() -> Option[T]: self.next()

impl[I, T] Iter[T] for TakeWhileIter[I, T]:
    mut fn next() -> Option[T]: self.next()

impl[I, T] Iter[T] for DropWhileIter[I, T]:
    mut fn next() -> Option[T]: self.next()

impl[A, B, T, U] Iter[(T, U)] for ZipIter[A, B, T, U]:
    mut fn next() -> Option[(T, U)]: self.next()

impl[I, T] Iter[(i64, T)] for EnumerateIter[I, T]:
    mut fn next() -> Option[(i64, T)]: self.next()

impl[A, B, T] Iter[T] for ChainIter[A, B, T]:
    mut fn next() -> Option[T]: self.next()

impl[I, T] Iter[T] for StepByIter[I, T]:
    mut fn next() -> Option[T]: self.next()

/// Index specification for multi-dimensional indexing.
/// Used by the MultiIndex trait. kind: 0=scalar, 1=slice, 2=ellipsis, 3=newaxis.
pub type IndexSpec {
    pub kind: i32,
    pub start: i64,
    pub stop: i64,
    pub step: i64,
    pub has_start: bool,
    pub has_stop: bool,
    pub has_step: bool,
}

// §13.3 (#1746): `it.collect[Vec]()` on any Iter[T] implementor, the one
// adapter that builds a collection, so it lives with Vec rather than in
// std.traits (which the core prelude, Vec-less, also loads).
/// `it.collect[Vec]()`: every element, in order.
pub fn iter_collect[T, I: Iter[T]](iter: I) -> Vec[T]:
    var i = iter
    var out: Vec[T] = Vec.new()
    while true:
        match i.next():
            None => break
            Some(x) => out.push(x)
    out

