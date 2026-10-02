//! expect-stdout: ok

// D21 supersedes A5's receiver-returning mutator rule. A direct `push` call
// returns Unit, so a helper returning the Vec names `xs` as its tail value. The
// ordinary return move transfers the sole owner to the caller, which drops the
// element and buffer exactly once.

use std.builtins.print_i32
var COUNT = 0

type W { tag: i32 }
impl Drop for W:
    fn drop(move self: Self):
        COUNT = COUNT + 1

fn make() -> Vec[W]:
    let xs: Vec[W] = Vec.new()
    xs.push(W { tag: 1 })
    xs

fn caller():
    let v = make()
    // caller owns the moved-out Vec; `v` drops it exactly once at scope exit.
    let n = v.len()

fn main:
    caller()
    if COUNT == 1:
        print("ok")
    else:
        print_i32(COUNT)
