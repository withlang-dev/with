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

enum E { A(List[W]) | B }

fn new_w(s: *mut i32) -> W:
    unsafe { W { ptr: with_alloc(24), slot: s } }

fn mkw(s: *mut i32) -> List[W]:
    let v: List[W] = List.new()
    v.push(new_w(s))
    v.push(new_w(s))
    v

fn run(s: *mut i32):
    let e = E.A(mkw(s))

fn main:
    var c = 0
    run(&raw mut c)
    print_i32(c)
