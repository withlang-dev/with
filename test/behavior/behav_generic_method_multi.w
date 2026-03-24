//! expect-stdout: ok
type Cell[T] { value: T }

fn Cell.get(self: Cell[T]) -> T: self.value

fn main:
    let c1 = Cell{ value: 42 }
    assert(c1.get() == 42)

    let x: i64 = 100
    let c2 = Cell{ value: x }
    assert(c2.get() == x)

    print("ok")
