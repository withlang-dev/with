//! expect-debug-alloc: leak count=0
// A7 (#606): struct-pattern discards — a `_` field pattern and a `..` rest —
// own the fields they discard in a consuming destructure. Every discarded
// Drop field must be freed exactly once.
use std.builtins.print_i32
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut c_void)

type W { ptr: *mut u8, slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            with_free(self.ptr)
            *self.slot = *self.slot + 1

type P { x: W, y: W, z: W }

fn new_w(s: *mut i32) -> W:
    unsafe { W { ptr: with_alloc(24), slot: s } }

fn mk(s: *mut i32) -> P:
    P { x: new_w(s), y: new_w(s), z: new_w(s) }

fn run_wildcard_field(s: *mut i32):
    let { x, y: _, z } = mk(s)

fn run_rest(s: *mut i32):
    let { x, .. } = mk(s)

fn main:
    var c = 0
    run_wildcard_field(&raw mut c)
    run_rest(&raw mut c)
    print_i32(c)
