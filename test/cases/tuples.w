fn swap(a: i32, b: i32) -> (i32, i32) =
    (b, a)

fn main() -> i32 =
    let pair = (10, 32)
    let x = pair.0
    let y = pair.1
    assert(x + y == 42)
    0
