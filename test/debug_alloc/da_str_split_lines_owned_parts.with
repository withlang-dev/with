//! expect-debug-alloc: leak count=0
use std.string

fn main:
    let parts = "alpha beta gamma".split(" ")
    let split_reuse = "x" ++ "y"
    assert(split_reuse == "xy")
    assert(parts.len() == 3)
    assert(parts[0] == "alpha")
    assert(parts[1] == "beta")
    assert(parts[2] == "gamma")

    let rows = lines("first\nsecond\nthird")
    let line_reuse = "u" ++ "v"
    assert(line_reuse == "uv")
    assert(rows.len() == 3)
    assert(rows[0] == "first")
    assert(rows[1] == "second")
    assert(rows[2] == "third")
