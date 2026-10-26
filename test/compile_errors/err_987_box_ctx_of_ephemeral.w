//! expect-check-fail: an ephemeral value cannot be stored on the heap
// #987 (§5.1): boxing a borrow-holding ephemeral for a C callback context is
// refused, as std.ffi now documents (its comment said it was not yet).
use std.ffi

type View ephemeral:
    r: &i32

fn main:
    let x = 5
    let v = View { r: &x }
    let _p = box_ctx(v)
