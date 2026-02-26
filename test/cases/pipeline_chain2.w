// Test: Pipeline chaining with multiple steps
fn add1(x: i32) -> i32: x + 1
fn mul2(x: i32) -> i32: x * 2

fn main -> i32:
    let result = 10 |> add1 |> mul2
    // (10 + 1) * 2 = 22
    if result == 22 then 0 else 1
