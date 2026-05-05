// std.collections — collection type surface imported by the prelude.
//
// Keep this module intentionally minimal for selfhost compatibility.
// The compiler still owns the lowering/runtime behavior for these
// collection types; this module provides the user-facing names so they
// resolve through normal imports instead of hardcoded sema allowlists.

/// A growable array. Create with `Vec.new()`, add with `.push()`,
/// read with `.get()`. Supports iteration via `.iter()`.
type Vec[T]  {
    ptr: *const T,
    len: i64,
    cap: i64,
    elem_size: i64,
}

/// Clone for Vec[T]: produces a deep copy by cloning each element.
impl[T: Clone] Clone for Vec[T]:
    fn clone(self: &Self) -> Self:
        var out: Vec[T] = Vec.new()
        for item in *self:
            out.push(item.clone())
        out

/// An unordered key-value map. Create with `HashMap.new()`,
/// insert with `.insert(key, val)`, read with `.get(key)`.
type HashMap[K, V]  {
    ptr: *const i8,
}

/// An unordered set of unique values. Create with `HashSet.new()`.
type HashSet[T]  {
    ptr: *const i8,
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

impl[T] Iter[T] for VecIter[T] =
    fn next(mut self: Self) -> Option[T]:
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
