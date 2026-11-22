//! expect-stdout: ok
type Cell[T] { value: T }

fn Cell.get(self: &Self) -> T: self.value
fn Cell.map_add(self: &Self, delta: T) -> T: self.value + delta

fn main:
    let c1 = Cell{ value: 42 }
    assert(c1.get() == 42)
    assert(c1.map_add(8) == 50)
    print("ok")
