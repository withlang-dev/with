//! expect-check-fail: unknown type 'U'

type Box[T] { value: T }

extend Box[T]:
    fn get(self: &Box[T]) -> U:
        self.value

fn main:
    let b: Box[i32] = Box { value: 1 }
    let _x = b.get()
