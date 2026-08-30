//! expect-debug-alloc: leak count=0
use std.builtins.print_i32
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit

type W { ptr: *mut u8, slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            with_free(self.ptr)
            *self.slot = *self.slot + 1

fn new_w(s: *mut i32) -> W:
    unsafe { W { ptr: with_alloc(24), slot: s } }

fn touch:
    ()

fn run(s: *mut i32, early: bool):
    var pair = (new_w(s), new_w(s))
    defer: touch()
    let first = move pair.0
    if early:
        return
    let second = move pair.1

fn main:
    var c = 0
    run(&raw mut c, true)
    run(&raw mut c, false)
    print_i32(c)
