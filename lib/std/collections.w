// std.collections — collection type surface imported by the prelude.
//
// Keep this module intentionally minimal for selfhost compatibility.
// The compiler still owns the lowering/runtime behavior for these
// collection types; this module provides the user-facing names so they
// resolve through normal imports instead of hardcoded sema allowlists.

type Vec[T]  {
    ptr: *const T,
    len: i64,
    cap: i64,
    elem_size: i64,
}

type HashMap[K, V]  {
    ptr: *const i8,
}

type HashSet[T]  {
    ptr: *const i8,
}

// ── Iterators ─────────────────────────────────────────────────────

// VecIter[T] — generic iterator over Vec[T].
// Stores a raw data pointer and iterates by index.
// .next() is a codegen intrinsic that returns Option[T].
type VecIter[T]  { data_ptr: i64, len: i64, idx: i64 }
