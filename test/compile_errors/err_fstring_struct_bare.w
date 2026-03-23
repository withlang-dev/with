//! expect-check-fail: struct type has no default display; use :? for debug
type Point = { x: i32, y: i32 }
fn main:
    let p = Point { x: 1, y: 2 }
    println(f"{p}")
