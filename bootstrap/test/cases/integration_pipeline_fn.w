// Integration test: pipeline with function composition
fn parse(s: str) -> i32:
    match s
        "one" -> 1
        "two" -> 2
        "three" -> 3
        _ -> 0

fn double(x: i32) -> i32: x * 2
fn add_ten(x: i32) -> i32: x + 10

fn main -> i32:
    let result = parse("three") |> double |> add_ten
    println(result)
    let r2 = parse("two") |> double
    println(r2)
