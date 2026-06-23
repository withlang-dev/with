//! expect-debug-alloc: leak count=0
type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1
type H { items: Vec[W] }
fn mkw(s: *mut i32) -> Vec[W]:
    let v: Vec[W] = Vec.new()
    v.push(W { slot: s })
    v.push(W { slot: s })
    v
fn run(s: *mut i32):
    let xs: Vec[W] = mkw(s)
    let _ = xs.len()
fn main:
    var c = 0
    run(&raw mut c)
    print_i32(c)
