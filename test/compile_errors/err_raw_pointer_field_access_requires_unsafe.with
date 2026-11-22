//! expect-error: raw pointer field access requires unsafe context

type Point { x: i32 }

fn main:
    var p = Point { x: 1 }
    let raw = &raw mut p as *mut Point
    let x = raw.x
