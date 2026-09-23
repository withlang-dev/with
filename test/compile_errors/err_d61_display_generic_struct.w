//! expect-error: type 'Pair[i32]' has no default display; use :? for debug

type Pair[T] { a: T, b: T }

fn main:
    let p = Pair { a: 1, b: 2 }
    print(f"{p}")
