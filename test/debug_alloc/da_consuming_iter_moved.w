//! expect-debug-alloc: leak count=0

// D33 (#724) acceptance rider: the iterator VALUE itself moves. Driving
// the moved iterator yields owned elements; the moved-from binding owns
// nothing, so every element still drops exactly once.
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
    var zs: Vec[W] = Vec.new()
    zs.push(new_w(&raw mut drops, 21))
    zs.push(new_w(&raw mut drops, 22))
    var src_iter = zs.into_iter()
    var driver = move src_iter
    var got = 0
    match driver.next():
        Some(w) => got = w.n
        None => got = -1
    // the yielded element dropped at the arm's end; the tail is still owned
    // by the moved-to iterator
    assert(got == 21)
    assert(drops == 1)
    print_i32(drops)
