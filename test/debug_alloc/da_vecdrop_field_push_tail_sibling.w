//! expect-debug-alloc: leak count=0
type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

type H { a: Vec[W], b: Vec[W] }

fn make_one(s: *mut i32) -> Vec[W]:
    let v: Vec[W] = Vec.new()
    v.push(W { slot: s })
    v

fn run(s: *mut i32):
    let h = H { a: Vec.new(), b: make_one(s) }
    h.a.push(W { slot: s })

fn main:
    var c = 0
    run(&raw mut c)
    print_i32(c)
