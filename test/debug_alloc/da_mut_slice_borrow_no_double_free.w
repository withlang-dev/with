//! expect-debug-alloc: leak count=0
// #604: a collection passed as a slice view is BORROWED — the callee neither
// frees nor copies the elements, and the caller's List drops them exactly once
// at scope exit. A header copy in the coercion would double-free.
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

fn count(xs: []W) -> i64:
    xs.len()

fn run(s: *mut i32):
    let v: List[W] = List.new()
    v.push(new_w(s))
    v.push(new_w(s))
    let n = count(v)
    let m = count(v)

fn main:
    var c = 0
    run(&raw mut c)
    print_i32(c)
