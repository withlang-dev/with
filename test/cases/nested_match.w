// Test: Nested match expressions
type Color = Red | Green | Blue

fn color_val(c: Color) -> i32 =
    match c
        Red -> 1
        Green -> 2
        Blue -> 3

fn combine(a: Color, b: Color) -> i32 =
    color_val(a) * 10 + color_val(b)

fn main() -> i32 =
    assert(combine(Red, Blue) == 13)
    assert(combine(Green, Green) == 22)
    assert(combine(Blue, Red) == 31)

    // Nested match in expressions
    let x = match Red
        Red -> match Green
            Green -> 42
            _ -> 0
        _ -> 0
    if x == 42 then 0 else 1
