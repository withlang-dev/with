// Test: pipeline operator with multiple stages and different arities
fn double(x: i32) -> i32: x * 2
fn add(a: i32, b: i32) -> i32: a + b
fn sub(a: i32, b: i32) -> i32: a - b
fn clamp(val: i32, max_val: i32) -> i32:
    if val > max_val then max_val else val
fn negate(x: i32) -> i32: 0 - x
fn abs_val(x: i32) -> i32:
    if x < 0 then 0 - x else x

fn main -> i32:
    // Long pipeline chain
    let result = 5 |> double |> add(3) |> double |> sub(6)
    // 5 -> 10 -> 13 -> 26 -> 20
    assert(result == 20)

    // Pipeline with clamp
    let clamped = 100 |> double |> clamp(150)
    // 100 -> 200 -> 150
    assert(clamped == 150)

    // Pipeline with negate and abs
    let val = 7 |> negate |> abs_val
    assert(val == 7)

    // Nested pipeline result used in expression
    let a = 3 |> double
    let b = 4 |> double
    let total = a + b
    assert(total == 14)

    // Pipeline with literal initial values
    let r1 = 0 |> add(10) |> double |> add(5)
    assert(r1 == 25)

    // Pipeline into boolean context
    let big = 50 |> double
    assert(big > 90)

    println("all pipeline_multi tests passed")
