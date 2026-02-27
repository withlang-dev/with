// Test pipeline operator with various functions
fn double(x: i32) -> i32: x * 2
fn negate(x: i32) -> i32: 0 - x
fn add_ten(x: i32) -> i32: x + 10

fn main -> i32:
    let r1 = 5 |> double
    let r2 = 5 |> double |> add_ten
    let r3 = 3 |> double |> negate |> add_ten
    println(r1)
    println(r2)
    println(r3)
