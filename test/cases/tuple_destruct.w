fn swap(a: i32, b: i32) -> (i32, i32) =
    (b, a)

fn main() -> i32 =
    let (x, y) = swap(10, 32)
    assert(x == 32)
    assert(y == 10)
    let (a, b) = (100, 200)
    assert(a == 100)
    assert(b == 200)
    0
