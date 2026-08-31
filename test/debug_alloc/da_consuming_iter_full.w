//! expect-debug-alloc: leak count=0

// D33 (#724): consuming iteration. `for x in vec.into_iter()` moves each
// element out exactly once — the sink becomes the sole owner, so total
// drops equal the element count and nothing frees twice or leaks.
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
    var xs: Vec[W] = Vec.new()
    xs.push(new_w(&raw mut drops, 1))
    xs.push(new_w(&raw mut drops, 2))
    xs.push(new_w(&raw mut drops, 3))
    var sink: Vec[W] = Vec.new()
    var total = 0
    for w in xs.into_iter():
        total = total + w.n
        sink.push(w)
    assert(total == 6)
    assert(sink.len() == 3)
    // sink still owns every element — nothing dropped yet
    assert(drops == 0)
    sink.clear()
    assert(drops == 3)
    print_i32(drops)
