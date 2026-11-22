//! expect-debug-alloc: leak count=0
// A6: a (W, W) tuple field two struct levels deep (Outer { Inner { pair } }).
// Drop must propagate through both struct layers into the tuple elements —
// each freed exactly once at the outer owner's scope exit.
use std.builtins.print_i32
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut c_void)

type W { ptr: *mut u8, slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            with_free(self.ptr)
            *self.slot = *self.slot + 1

type Inner { pair: (W, W) }
type Outer { inner: Inner }

fn new_w(s: *mut i32) -> W:
    unsafe { W { ptr: with_alloc(24), slot: s } }

fn run(s: *mut i32):
    let outer = Outer { inner: Inner { pair: (new_w(s), new_w(s)) } }

fn main:
    var c = 0
    run(&raw mut c)
    print_i32(c)
