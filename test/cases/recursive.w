fn factorial(n: i32) -> i32 =
    if n <= 1 then 1
    else n * factorial(n - 1)

fn main() -> i32 =
    assert(factorial(5) == 120)
    0
