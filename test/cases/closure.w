fn apply(f: fn(i32) -> i32, x: i32) -> i32 =
    f(x)

fn main() -> i32 =
    let inc = |x| x + 1
    assert(apply(inc, 41) == 42)
    0
