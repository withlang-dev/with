//! only-on: darwin
//! expect-debug-alloc: debug-alloc: first free (innermost first
// #1014: a double free names the first free's calling chain, kept in the
// ledger, and then the second's. Darwin unwinds in-process; the other
// backends print the tags only.
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut c_void)
fn main:
    unsafe:
        let p = with_alloc(64)
        with_free(p)
        with_free(p)
