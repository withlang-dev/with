//! expect-debug-alloc: leak count=0
// #607: a transitive-Drop field (Vec[W]) moved out of a non-Drop struct via
// let / return-tail / move-self / destructure. The moved elements and the
// sibling field are each freed exactly once — no leak, no double free.
use std.builtins.print_i32
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit

type W { ptr: *mut u8, slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            with_free(self.ptr)
            *self.slot = *self.slot + 1

type Holder { a: Vec[W], b: W }

fn new_w(s: *mut i32) -> W:
    unsafe { W { ptr: with_alloc(24), slot: s } }

fn mk(s: *mut i32) -> Holder:
    let v: Vec[W] = Vec.new()
    v.push(new_w(s))
    v.push(new_w(s))
    Holder { a: v, b: new_w(s) }

fn Holder.into_values(move self: Holder) -> Vec[W]:
    var owned = self
    return move owned.a

fn take(h: Holder) -> Vec[W]:
    var owned = h
    return move owned.a

fn run_let(s: *mut i32):
    var h = mk(s)
    let m = move h.a

fn run_tail(s: *mut i32):
    let v = take(mk(s))

fn run_moveself(s: *mut i32):
    let h = mk(s)
    let v = h.into_values()

fn run_destructure(s: *mut i32):
    let { a, b } = mk(s)

fn main:
    var c = 0
    run_let(&raw mut c)
    run_tail(&raw mut c)
    run_moveself(&raw mut c)
    run_destructure(&raw mut c)
    print_i32(c)
