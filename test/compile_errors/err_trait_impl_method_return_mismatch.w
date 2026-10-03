//! expect-check-fail: return type does not match trait

trait Sink:
    fn set(mut self: Self, value: i32)

type Cell {
    value: i32,
}

impl Sink for Cell:
    fn set(mut self: Self, v: i32) -> i32:
        v

fn main:
    var c = Cell { value: 0 }
    c.set(1)
