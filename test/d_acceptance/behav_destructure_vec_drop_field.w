//! expect-stdout: ok

// #607: destructuring a Vec[Drop] field out of a by-value struct in a match
// arm moves the field into the binding, which becomes its sole owner — one
// element drop, no double free. (Was err_destructure_vec_drop_field before
// the #607 boundary was lifted.)

use std.builtins.print_i32
type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

type H { items: Vec[W] }

fn run(s: *mut i32):
    let xs: Vec[W] = Vec.new()
    xs.push(W { slot: s })
    let h = H { items: xs }
    match h:
        H { items } => ()

fn main:
    var c = 0
    run(&raw mut c)
    if c == 1:
        print("ok")
    else:
        print_i32(c)
