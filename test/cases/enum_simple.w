type Color = Red | Green | Blue

fn color_value(c: Color) -> i32:
    match c
        Red -> 1
        Green -> 2
        Blue -> 3

fn main -> i32:
    let r = Red
    let g = Green
    let b = Blue
    assert(color_value(r) + color_value(g) + color_value(b) + 36 == 42)
