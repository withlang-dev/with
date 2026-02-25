fn add(a: i32, b: i32) -> i32 = a + b

fn double(x: i32) -> i32 = add(x, x)

fn main() -> i32 =
    assert(double(21) == 42)
    0
