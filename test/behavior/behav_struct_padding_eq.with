//! expect-stdout: ok
type Pair { a: i32, b: i64 }

fn main:
    let x = Pair { a: 1, b: 100 }
    let y = Pair { a: 1, b: 100 }
    assert(x == y)
    let z = Pair { a: 2, b: 100 }
    assert(x != z)
    print("ok")
