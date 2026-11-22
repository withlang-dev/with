//! expect-stdout: ok

// #1695: a module's own `extern fn strerror` governs its calls even when an
// imported std module (std.fs) declares the same extern; the call still
// needs `unsafe`, and the block that has it is not "without unsafe
// operations".
use std.fs
extern fn strerror(errnum: i32) -> *mut i8
fn main:
    let p = unsafe { strerror(2) }
    if p as i64 != 0: print("ok")
