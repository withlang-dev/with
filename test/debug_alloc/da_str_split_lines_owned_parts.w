//! expect-debug-alloc: leak count=0
use std.string

fn main:
    let parts = "alpha beta gamma".split(" ")
    let split_reuse = "x" ++ "y"
    assert(split_reuse == "xy")
    assert(parts.len() == 3)
    assert(parts.get(0) == "alpha")
    assert(parts.get(1) == "beta")
    assert(parts.get(2) == "gamma")

    let rows = lines("first\nsecond\nthird")
    let line_reuse = "u" ++ "v"
    assert(line_reuse == "uv")
    assert(rows.len() == 3)
    assert(rows.get(0) == "first")
    assert(rows.get(1) == "second")
    assert(rows.get(2) == "third")
