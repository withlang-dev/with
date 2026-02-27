fn double(x: i32) -> i32: x * 2
fn inc(x: i32) -> i32: x + 1
fn square(x: i32) -> i32: x * x

fn main -> i32:
    let a = 3 |> double |> inc
    println(a)
    let b = 5 |> inc |> double
    println(b)
    let c = 2 |> square |> double
    println(c)
