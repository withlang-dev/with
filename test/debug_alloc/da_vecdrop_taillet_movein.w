//! expect-debug-alloc: leak count=0
use std.builtins.print_i32
type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1
type H { items: List[W] }
fn mkw(s: *mut i32) -> List[W]:
    let v: List[W] = List.new()
    v.push(W { slot: s })
    v.push(W { slot: s })
    v
fn run(s: *mut i32):
    let h = H { items: mkw(s) }
fn main:
    var c = 0
    run(&raw mut c)
    print_i32(c)
