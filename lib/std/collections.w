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

/// An unordered key-value map. Create with `HashMap.new()`,
/// insert with `.insert(key, val)`, read with `.get(key)`.
type HashMap[K, V]  {
    ptr: *const i8,
}

/// An unordered set of unique values. Create with `HashSet.new()`.
type HashSet[T]  {
    ptr: *const i8,
}

// ── Iterators ─────────────────────────────────────────────────────

/// Iterator over Vec[T]. Obtain via `vec.iter()`.
/// Call `.next()` to get `Option[T]` — `Some(val)` or `None`.
type VecIter[T]  { data_ptr: i64, len: i64, idx: i64 }
