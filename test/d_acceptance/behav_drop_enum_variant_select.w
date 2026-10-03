//! expect-stdout: ok

// #606: enum drop is variant-aware -- only the ACTIVE variant's payload drops.
// B(i32) carries no Drop payload, so constructing B must not drop a phantom W.

type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

enum E { A(W) | B(i32) }

fn run_a(slot: *mut i32):
    let e = E.A(W { slot: slot })

fn run_b(slot: *mut i32):
    let e = E.B(7)

fn main:
    var ca = 0
    run_a(&raw mut ca)
    var cb = 0
    run_b(&raw mut cb)
    if ca == 1 and cb == 0:
        print("ok")
    else:
        print_i32(ca)
        print_i32(cb)
