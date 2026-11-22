//! expect-build-fail: unknown method 'get' for type 'Cell[i32]'

type Box[T] { value: T }
type Cell[T] { value: T }

extend Box[T]:
    fn get(self: &Box[T]) -> T:
        self.value

fn main:
    let c: Cell[i32] = Cell { value: 1 }
    let _x = c.get()
