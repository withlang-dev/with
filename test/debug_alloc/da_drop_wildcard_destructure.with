//! expect-debug-alloc: leak count=0
// A7 (#606): a `_` in an irrefutable destructure receives ownership of the
// value it discards. The discarded element must still be freed exactly once
// (anonymous drop-local); the source tuple's consume must not orphan it.
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

fn run_one(s: *mut i32):
    let (a, _) = make(s)

fn run_both(s: *mut i32):
    let (_, _) = make(s)

fn run_named(s: *mut i32):
    let t = make(s)
    let (a, _) = t

fn run_nested(s: *mut i32):
    let ((a, _), b) = ((new_w(s), new_w(s)), new_w(s))

fn main:
    var c = 0
    run_one(&raw mut c)
    run_both(&raw mut c)
    run_named(&raw mut c)
    run_nested(&raw mut c)
    print_i32(c)
