//! expect-stdout: ok
type Cell[T] { value: T }

fn Cell.get(self: Cell[T]) -> T: self.value
fn Cell.map_add(self: Cell[T], delta: T) -> T: self.value + delta

fn main:
    let c1 = Cell{ value: 42 }
    assert(c1.get() == 42)
    assert(c1.map_add(8) == 50)
    print("ok")
