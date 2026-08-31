//! expect-debug-alloc: leak count=0

// D33/#912: comprehensions over consuming iterators. Filtered-OUT owned
// elements drop on their iteration's back-edge; filtered-in elements
// drop after their projection; an identity comprehension MOVES elements
// into the output (none drop until the output does). Each exactly once.
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
    // projection with filter: every element drops during the loop
    var drops = 0
    var xs: Vec[W] = Vec.new()
    xs.push(new_w(&raw mut drops, 1))
    xs.push(new_w(&raw mut drops, 2))
    xs.push(new_w(&raw mut drops, 3))
    let odd: Vec[i32] = [w.n for w in xs.into_iter() if w.n % 2 == 1]
    assert(odd.len() == 2)
    assert(drops == 3)

    // identity: elements move into the output; ownership transfers whole
    var drops2 = 0
    var ys: Vec[W] = Vec.new()
    ys.push(new_w(&raw mut drops2, 7))
    ys.push(new_w(&raw mut drops2, 8))
    var kept: Vec[W] = [w for w in ys.into_iter()]
    assert(kept.len() == 2)
    assert(drops2 == 0)
    kept.clear()
    assert(drops2 == 2)
    print_i32(drops + drops2)
