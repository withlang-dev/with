//! expect-debug-alloc: leak count=0

// D33 (#724): breaking out of a consuming loop is Higher RAII — the loop
// variable drops its element at the break edge and the iterator drops the
// un-yielded tail plus the buffer, each exactly once, before the code
// after the loop runs.
use std.builtins.print_i32
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit

type W { ptr: *mut u8, drops: *mut i32, n: i32 }

impl Drop for W:
    move fn drop():
        unsafe:
            with_free(self.ptr)
            *self.drops = *self.drops + 1

fn new_w(drops: *mut i32, n: i32) -> W:
    unsafe { W { ptr: with_alloc(24), drops, n } }

fn main:
    var drops = 0
    var ys: Vec[W] = Vec.new()
    ys.push(new_w(&raw mut drops, 11))
    ys.push(new_w(&raw mut drops, 12))
    ys.push(new_w(&raw mut drops, 13))
    var first = 0
    for w in ys.into_iter():
        first = w.n
        break
    // yielded element + two-element tail: all three dropped at the break,
    // none of them twice
    assert(first == 11)
    assert(drops == 3)
    print_i32(drops)
