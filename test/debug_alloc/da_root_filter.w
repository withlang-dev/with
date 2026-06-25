//! debug-alloc-filter: non-root
//! expect-debug-alloc: leak count=0

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_debug_alloc_mark_root(ptr: *mut u8, reason: *const u8, reason_len: i64) -> Unit

fn main:
    unsafe:
        let p = with_alloc(32)
        with_debug_alloc_mark_root(p, c"fixture-root".ptr, 12)
