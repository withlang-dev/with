//! expect-debug-alloc: leak count=0
// A6: a (W, W) tuple field of a struct. Both tuple elements must be freed
// exactly once when the owning struct goes out of scope — a missed element
// drop leaks; a duplicate element drop double-frees.
use std.builtins.print_i32
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut c_void)

type W { ptr: *mut u8, slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            with_free(self.ptr)
            *self.slot = *self.slot + 1

type H { pair: (W, W) }

fn new_w(s: *mut i32) -> W:
    unsafe { W { ptr: with_alloc(24), slot: s } }

fn run(s: *mut i32):
    let h = H { pair: (new_w(s), new_w(s)) }

fn main:
    var c = 0
    run(&raw mut c)
    print_i32(c)
