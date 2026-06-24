//! expect-debug-alloc: leak count=0
type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

type H { items: Vec[W] }

fn run(s: *mut i32):
    let h = H { items: Vec.new() }
    h.items.push(W { slot: s }).push(W { slot: s })

fn main:
    var c = 0
    run(&raw mut c)
    print_i32(c)
