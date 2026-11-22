//! expect-check-fail: cannot infer return type: if arms have types i32 and Unit; add `-> i32` or `-> Unit`

// D43: the block-body spelling gets the same answer as the single-statement one.

var seen: i32
fn bump(x: i32) -> i32: x + 1
fn f(p: bool):
    seen = 0
    if p: bump(1)
    else: print("no")

fn main: f(true)
