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
impl[T:
    Clone] Clone for Vec[T]:
    fn clone(self: &Self) -> Self:
        var out: Vec[T] = Vec.new()
        for item in *self:
            out.push(item.clone())
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

pub fn BTreeMap.len[K: Ord, V](self: &BTreeMap[K, V]) -> i64:
    self.entries.len()

pub fn BTreeMap.is_empty[K, V](self: &BTreeMap[K, V]) -> bool:
    self.entries.len() == 0

pub fn BTreeMap.clear[K, V](mut self: BTreeMap[K, V]) -> Unit:
    self.entries.clear()

fn BTreeMap.last_index_of[K: Ord, V](self: &BTreeMap[K, V], key: K) -> i64:
    var found = -1
    var i = 0
    while i < self.entries.len():
        let (existing, _) = self.entries.get(i)
        if not (existing < key) and not (existing > key):
            found = i
        i = i + 1
    found

pub fn BTreeMap.contains[K: Ord, V](self: &BTreeMap[K, V], key: K) -> bool:
    var i = 0
    while i < self.entries.len():
        let (existing, _) = self.entries.get(i)
        if not (existing < key) and not (existing > key):
            return true
        i = i + 1
    false

pub fn BTreeMap.get[K: Ord, V](self: &BTreeMap[K, V], key: K) -> Option[V]:
    let idx = self.last_index_of(key)
    if idx < 0:
        return None
    let (_, value) = self.entries.get(idx)
    Some(value)

pub fn BTreeMap.insert[K: Ord, V](mut self: BTreeMap[K, V], key: K, value: V) -> Unit:
    var i = 0
    while i < self.entries.len():
        let (existing, _) = self.entries.get(i)
        if not (existing < key) and not (existing > key):
            with self.entries.slot(i) as mut slot:
                slot.set((key, value))
            return
        if existing > key:
            self.entries.push((key, value))
            var j = self.entries.len() - 1
            while j > i:
                let left = self.entries.get(j - 1)
                let right = self.entries.get(j)
                with self.entries.slot(j - 1) as mut left_slot:
                    left_slot.set(right)
                with self.entries.slot(j) as mut right_slot:
                    right_slot.set(left)
                j = j - 1
            return
        i = i + 1
    self.entries.push((key, value))

pub fn BTreeMap.remove[K: Ord, V](mut self: BTreeMap[K, V], key: K) -> Option[V]:
    let idx = self.last_index_of(key)
    if idx < 0:
        return None
    let (_, removed_value) = self.entries.get(idx)
    var i = 0
    while i < self.entries.len():
        let (existing, _) = self.entries.get(i)
        if not (existing < key) and not (existing > key):
            let _ = self.entries.remove(i)
        else:
            i = i + 1
    Some(removed_value)

pub fn BTreeMap.keys[K: Ord, V](self: &BTreeMap[K, V]) -> Vec[K]:
    let out: Vec[K] = Vec.new()
    var entry_i = 0
    while entry_i < self.entries.len():
        let (key, _) = self.entries.get(entry_i)
        out.push(key)
        entry_i = entry_i + 1
    out

pub fn BTreeMap.values[K: Ord, V](self: &BTreeMap[K, V]) -> Vec[V]:
    let out: Vec[V] = Vec.new()
    var entry_i = 0
    while entry_i < self.entries.len():
        let (_, value) = self.entries.get(entry_i)
        out.push(value)
        entry_i = entry_i + 1
    out

pub fn BTreeMap.items[K: Ord, V](self: &BTreeMap[K, V]) -> Vec[(K, V)]:
    let out: Vec[(K, V)] = Vec.new()
    var entry_i = 0
    while entry_i < self.entries.len():
        let (key, value) = self.entries.get(entry_i)
        out.push((key, value))
        entry_i = entry_i + 1
    out

impl[K: Ord, V] IntoIter[(K, V)] for BTreeMap[K, V]:
    fn iter(mut self: BTreeMap[K, V]) -> VecIter[(K, V)]:
        self.entries.iter()

pub fn BTreeSet.new[T]() -> BTreeSet[T]:
    BTreeSet { values: Vec.new() }

pub fn BTreeSet.len[T: Ord](self: &BTreeSet[T]) -> i64:
    self.values.len()

pub fn BTreeSet.is_empty[T](self: &BTreeSet[T]) -> bool:
    self.values.len() == 0

pub fn BTreeSet.clear[T](mut self: BTreeSet[T]) -> Unit:
    self.values.clear()

fn BTreeSet.index_of[T: Ord](self: &BTreeSet[T], value: T) -> i64:
    var i = 0
    while i < self.values.len():
        let existing = self.values.get(i)
        if not (existing < value) and not (existing > value):
            return i
        i = i + 1
    -1

pub fn BTreeSet.contains[T: Ord](self: &BTreeSet[T], value: T) -> bool:
    var i = 0
    while i < self.values.len():
        let existing = self.values.get(i)
        if not (existing < value) and not (existing > value):
            return true
        i = i + 1
    false

pub fn BTreeSet.insert[T: Ord](mut self: BTreeSet[T], value: T) -> Unit:
    var i = 0
    while i < self.values.len():
        let existing = self.values.get(i)
        if not (existing < value) and not (existing > value):
            with self.values.slot(i) as mut slot:
                slot.set(value)
            return
        if existing > value:
            self.values.push(value)
            var j = self.values.len() - 1
            while j > i:
                let left = self.values.get(j - 1)
                let right = self.values.get(j)
                with self.values.slot(j - 1) as mut left_slot:
                    left_slot.set(right)
                with self.values.slot(j) as mut right_slot:
                    right_slot.set(left)
                j = j - 1
            return
        i = i + 1
    self.values.push(value)

pub fn BTreeSet.remove[T: Ord](mut self: BTreeSet[T], value: T) -> bool:
    let idx = self.index_of(value)
    if idx < 0:
        return false
    var i = 0
    while i < self.values.len():
        let existing = self.values.get(i)
        if not (existing < value) and not (existing > value):
            let _ = self.values.remove(i)
        else:
            i = i + 1
    true

pub fn BTreeSet.items[T: Ord](self: &BTreeSet[T]) -> Vec[T]:
    let out: Vec[T] = Vec.new()
    var value_i = 0
    while value_i < self.values.len():
        let value = self.values.get(value_i)
        out.push(value)
        value_i = value_i + 1
    out

pub fn BTreeSet.union[T: Ord](self: &BTreeSet[T], other: &BTreeSet[T]) -> BTreeSet[T]:
    let out: BTreeSet[T] = BTreeSet[T].new()
    var self_i = 0
    while self_i < self.values.len():
        let value = self.values.get(self_i)
        out.insert(value)
        self_i = self_i + 1
    var other_i = 0
    while other_i < other.values.len():
        let value2 = other.values.get(other_i)
        out.insert(value2)
        other_i = other_i + 1
    out

pub fn BTreeSet.intersection[T: Ord](self: &BTreeSet[T], other: &BTreeSet[T]) -> BTreeSet[T]:
    let out: BTreeSet[T] = BTreeSet[T].new()
    var self_i = 0
    while self_i < self.values.len():
        let value = self.values.get(self_i)
        if other.contains(value):
            out.insert(value)
        self_i = self_i + 1
    out

pub fn BTreeSet.difference[T: Ord](self: &BTreeSet[T], other: &BTreeSet[T]) -> BTreeSet[T]:
    let out: BTreeSet[T] = BTreeSet[T].new()
    var self_i = 0
    while self_i < self.values.len():
        let value = self.values.get(self_i)
        if not other.contains(value):
            out.insert(value)
        self_i = self_i + 1
    out

impl[T: Ord] IntoIter[T] for BTreeSet[T]:
    fn iter(mut self: BTreeSet[T]) -> VecIter[T]:
        self.values.iter()

/// Type-safe generational handle into a SlotMap[T].
/// Handles are Copy and carry their owner element type at compile time, so a
/// Handle[Texture] cannot be used with a SlotMap[Mesh].
pub type Handle[T] {
    index: u32,
    generation: u32,
}

impl[T] Copy for Handle[T]

impl[T] Eq for Handle[T]:    fn eq(self: Handle[T], other:
    Handle[T]) -> bool:
        self.index == other.index and self.generation == other.generation

impl[T] Hash for Handle[T]:    fn hash_value(self:
    Handle[T]) -> i64:
        ((self.index as i64) << 32) ^ (self.generation as i64)

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
type VecSlot[T] ephemeral { data_ptr: i64, index: i64 }

/// Iterator yielding VecSlot[T] handles for in-place element mutation (§19.5).
/// Obtain via `vec.iter_place()`. Each `.next()` returns `Option[VecSlot[T]]`.
type VecIterPlace[T] ephemeral { data_ptr: i64, len: i64, idx: i64 }

/// Scoped handle to a HashMap entry (docs/mut.md Rev 8 §10).
/// Obtain via `map.entry(key)`. Use with `with`:
///   with map.entry(k) as mut e:
///       e.or_insert(default)
type HashMapEntry[K, V] ephemeral { map_ptr: i64, key: K }

// ── Iterators ─────────────────────────────────────────────────────

/// Iterator over Vec[T]. Obtain via `vec.iter()`.
/// Call `.next()` to get `Option[T]` — `Some(val)` or `None`.
type VecIter[T] ephemeral { data_ptr: i64, len: i64, idx: i64 }

/// Conversion to iterator for allocation-backed collection types.
pub trait IntoIter[T]:
    fn iter(self) -> VecIter[T]

// IntoIter for Vec — enables collection-level async combinators and
// explicit trait dispatch over Vec-backed collections.
impl[T] IntoIter[T] for Vec[T]:    fn iter(self:
    Vec[T]) -> VecIter[T]:
        self.iter()

/// Lazy iterator adapter produced by `.map(f)`.
type MapIter[I, T, U] ephemeral { iter: I, f: fn(T) -> U }

/// Lazy iterator adapter produced by `.filter(pred)`.
type FilterIter[I, T] ephemeral { iter: I, pred: fn(T) -> bool }

/// Lazy iterator adapter produced by `.filter_map(f)`.
type FilterMapIter[I, T, U] ephemeral { iter: I, f: fn(T) -> Option[U] }

/// Lazy iterator adapter produced by `.take(n)`.
type TakeIter[I, T] ephemeral { iter: I, remaining: i64 }

/// Lazy iterator adapter produced by `.drop(n)`.
type DropIter[I, T] ephemeral { iter: I, remaining: i64 }

/// Lazy iterator adapter produced by `.take_while(pred)`.
type TakeWhileIter[I, T] ephemeral { iter: I, pred: fn(T) -> bool, done: bool }

/// Lazy iterator adapter produced by `.drop_while(pred)`.
type DropWhileIter[I, T] ephemeral { iter: I, pred: fn(T) -> bool, dropping: bool }

/// Lazy iterator adapter produced by `.zip(other)`.
type ZipIter[A, B, T, U] ephemeral { left: A, right: B }

/// Lazy iterator adapter produced by `.enumerate()`.
type EnumerateIter[I, T] ephemeral { iter: I, idx: i64 }

/// Lazy iterator adapter produced by `.chain(other)`.
type ChainIter[A, B, T] ephemeral { left: A, right: B, use_right: bool }

/// Lazy iterator adapter produced by `.zip_with(other, f)`.
type ZipWithIter[A, B, T, U, V] ephemeral { left: A, right: B, f: fn(T, U) -> V }

/// Lazy iterator adapter produced by `.step_by(n)`.
type StepByIter[I, T] ephemeral { iter: I, step: i64, first: bool }

/// Lazy iterator adapter produced by `.flat_map(f)`.
type FlatMapIter[I, C, J, T, U] ephemeral {
    iter: I,
    f: fn(T) -> C,
    current: J,
    has_current: bool,
}

impl[T] Iter[T] for VecIter[T]:    fn next(mut self:
    Self) -> Option[T]:
        self.next()

/// Index specification for multi-dimensional indexing.
/// Used by the MultiIndex trait. kind: 0=scalar, 1=slice, 2=ellipsis, 3=newaxis.
pub type IndexSpec {
    kind: i32,
    start: i64,
    stop: i64,
    step: i64,
    has_start: bool,
    has_stop: bool,
    has_step: bool,
}
