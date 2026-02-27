// Test chained pipeline operations
fn double(x: i32) -> i32: x * 2
fn add_one(x: i32) -> i32: x + 1
fn square(x: i32) -> i32: x * x

fn main -> i32:
    // Chain: 3 |> double |> add_one => 7
    let result = 3 |> double |> add_one
    println(result)

    // Chain: 2 |> add_one |> square => 9
    let r2 = 2 |> add_one |> square
    println(r2)
