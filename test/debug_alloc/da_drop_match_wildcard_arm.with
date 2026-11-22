//! expect-debug-alloc: leak count=0
// A7 (#606): match takes ownership of its subject; a `_` in the taken arm —
// as a discarded tuple element or as the whole-subject wildcard arm — owns
// what it discards and must free it exactly once, not leak it.
use std.builtins.print_i32
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut c_void)

type W { ptr: *mut u8, slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            with_free(self.ptr)
            *self.slot = *self.slot + 1

fn new_w(s: *mut i32) -> W:
    unsafe { W { ptr: with_alloc(24), slot: s } }

fn make(s: *mut i32) -> (W, W):
    (new_w(s), new_w(s))

fn run_elem(s: *mut i32):
    match make(s):
        (a, _) => ()

fn run_whole(s: *mut i32):
    match make(s):
        _ => ()

fn main:
    var c = 0
    run_elem(&raw mut c)
    run_whole(&raw mut c)
    print_i32(c)
