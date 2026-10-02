//! expect-stdout: ok

// D21: an rvalue receiver is materialized as one hidden place. Unit-returning
// `mut self` stages keep carrying that same place, and ordinary assignment-move
// transfers it into `v` because it remains the pipeline's final value. There are
// no receiver-returning aliases or intermediate owners; `v` drops both elements
// and the Vec buffer exactly once.

use std.builtins.print_i32
var COUNT = 0

type W { tag: i32 }
impl Drop for W:
    fn drop(move self: Self):
        COUNT = COUNT + 1

fn body() -> i64:
    let v: Vec[W] = Vec.new() |> push(W { tag: 1 }) |> push(W { tag: 2 })
    // Bind, then use v with trailing code: capture must move the hidden place.
    v.len()

fn main:
    let n = body()
    if COUNT == 2 and n == 2:
        print("ok")
    else:
        print_i32(COUNT)
