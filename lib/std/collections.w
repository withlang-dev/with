// std.collections — collection type surface imported by the prelude.
//
// Keep this module intentionally minimal for selfhost compatibility.
// The compiler still owns the lowering/runtime behavior for these
// collection types; this module provides the user-facing names so they
// resolve through normal imports instead of hardcoded sema allowlists.

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
pub type SlotMapSlot[T] {
    map_ptr: i64,
    index: u32,
    generation: u32,
}

/// Memory ordering for atomic operations.
enum Order: i32:
    Relaxed = 0
    Acquire = 1
    Release = 2
    AcqRel = 3
    SeqCst = 4

/// Atomic memory fence. Enforces ordering without an associated operation.
fn fence(order: Order):
    // Compiler intrinsic — body is replaced by MIR_INTRINSIC_ATOMIC_FENCE
    0

/// Lock-free atomic operations on integer types.
/// Create with `Atomic.new(0)`, read with `.load(.acquire)`,
/// write with `.store(val, .release)`.
type Atomic[T]  {
    val: T,
}

// ── Scoped access ────────────────────────────────────────────────

/// Scoped handle to a single Vec element (docs/mut.md Rev 8 §10).
/// Obtain via `vec.slot(index)`. Use with `with`:
///   with xs.slot(i) as mut s:
///       let v = s.get()
///       s.set(v + 1)
type VecSlot[T]  { data_ptr: i64, index: i64 }

/// Iterator yielding VecSlot[T] handles for in-place element mutation (§19.5).
/// Obtain via `vec.iter_place()`. Each `.next()` returns `Option[VecSlot[T]]`.
type VecIterPlace[T]  { data_ptr: i64, len: i64, idx: i64 }

/// Scoped handle to a HashMap entry (docs/mut.md Rev 8 §10).
/// Obtain via `map.entry(key)`. Use with `with`:
///   with map.entry(k) as mut e:
///       e.or_insert(default)
type HashMapEntry[K, V]  { map_ptr: i64, key: K }

// ── Iterators ─────────────────────────────────────────────────────

/// Iterator over Vec[T]. Obtain via `vec.iter()`.
/// Call `.next()` to get `Option[T]` — `Some(val)` or `None`.
type VecIter[T]  { data_ptr: i64, len: i64, idx: i64 }

/// Lazy iterator adapter produced by `.map(f)`.
type MapIter[I, T, U] { iter: I, f: fn(T) -> U }

/// Lazy iterator adapter produced by `.filter(pred)`.
type FilterIter[I, T] { iter: I, pred: fn(T) -> bool }

/// Lazy iterator adapter produced by `.take(n)`.
type TakeIter[I, T] { iter: I, remaining: i64 }

/// Lazy iterator adapter produced by `.zip(other)`.
type ZipIter[A, B, T, U] { left: A, right: B }

/// Lazy iterator adapter produced by `.flat_map(f)`.
type FlatMapIter[I, C, J, T, U] {
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
