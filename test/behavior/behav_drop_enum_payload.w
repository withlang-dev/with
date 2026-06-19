//! expect-stdout: ok

// #606: a Drop value in an enum variant payload is dropped when the enum drops.

type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

enum E { A(W) | B }

fn run(slot: *mut i32):
    let e = E.A(W { slot: slot })

fn main:
    var count = 0
    run(&raw mut count)
    if count == 1:
        print("ok")
    else:
        print_i32(count)
