//! expect-stdout: ok

// #605 + #606: matching an enum and binding the payload moves it out of the
// subject. The subject must be consumed so its payload-drop does not also free
// the moved-out binding (which would count 2).

type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

enum E { A(W) | B }

fn run(slot: *mut i32):
    let e = E.A(W { slot: slot })
    match e:
        .A(w) => ()
        .B => ()

fn main:
    var count = 0
    run(&raw mut count)
    if count == 1:
        print("ok")
    else:
        print_i32(count)
