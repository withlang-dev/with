//! expect-stdout: ok

type Box[T] { value: T }

extend Box[T]:
    fn get(self: &Box[T]) -> T:
        self.value

extend Vec[T]:
    fn is_empty(self: &Vec[T]) -> bool:
        self.len() == 0

fn main:
    let b: Box[i32] = Box { value: 42 }
    assert(b.get() == 42)

    var xs = Vec[i32].new()
    assert(xs.is_empty())
    xs.push(7)
    assert(not xs.is_empty())

    print("ok")
