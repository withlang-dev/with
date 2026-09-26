//! expect-check-fail: manual extern function call requires unsafe context

// #1695: the same call outside `unsafe` is refused; std.fs's declaration of
// the name does not make this module's own extern exempt.
use std.fs
extern fn strerror(errnum: i32) -> *mut i8
fn main:
    let p = strerror(2)
    if p as i64 != 0: print("ok")
