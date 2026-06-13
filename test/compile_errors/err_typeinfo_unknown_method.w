//! expect-check-fail: type method 'frobnicate' is not comptime-evaluable yet

type Point { x: i32 }

const BAD = comptime TypeInfo.frobnicate[Point]()

fn main:
    let _ = BAD
