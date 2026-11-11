//! only-on: darwin
//! expect-debug-alloc: debug-alloc:   allocated at (innermost first)
// #1014: a leaked block names the chain that allocated it.
extern fn with_alloc(size: i64) -> *mut u8
fn main:
    let p = unsafe { with_alloc(48) }
    print("leaked")
