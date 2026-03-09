// std.collections — collection type surface imported by the prelude.
//
// Keep this module intentionally minimal for selfhost compatibility.
// The compiler still owns the lowering/runtime behavior for these
// collection types; this module provides the user-facing names so they
// resolve through normal imports instead of hardcoded sema allowlists.

type Vec[T] = {
    ptr: *const T,
    len: i64,
    cap: i64,
    elem_size: i64,
}

type HashMap[K, V] = {
    ptr: *const i8,
}

type HashSet[T] = {
    ptr: *const i8,
}

// ── Iterators ─────────────────────────────────────────────────────

// VecIter_i32 — concrete iterator for Vec[i32].
// Stores a raw data pointer and iterates by index.
type VecIter_i32 = { data_ptr: i64, len: i64, idx: i64 }

extern fn with_ptr_get_i32(ptr: i64, index: i64) -> i32

fn VecIter_i32.next(self: VecIter_i32) -> Option[i32]:
    if self.idx >= self.len:
        return .None
    let val = with_ptr_get_i32(self.data_ptr, self.idx)
    self.idx = self.idx + 1
    .Some(val)

pub fn vec_iter_i32(v: Vec[i32]) -> VecIter_i32:
    VecIter_i32{ data_ptr: v.ptr as i64, len: v.len(), idx: 0 }
