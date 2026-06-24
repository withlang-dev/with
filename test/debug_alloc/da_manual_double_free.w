//! expect-debug-alloc: DOUBLE FREE
// Manual double-free: the ledger must detect freeing the same block twice.
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8)
fn main:
    unsafe:
        let p = with_alloc(64)
        with_free(p)
        with_free(p)
