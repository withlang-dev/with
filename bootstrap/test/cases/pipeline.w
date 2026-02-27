fn double(x: i32) -> i32: x * 2

fn add(a: i32, b: i32) -> i32: a + b

fn main -> i32:
    let x = 10 |> double
    let y = x |> add(1)
    assert(y == 21)
