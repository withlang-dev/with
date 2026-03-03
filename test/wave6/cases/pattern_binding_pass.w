// Wave 6 unit test: pattern bindings and destructuring
// Covers: match, enum variants, field access, let binding

type Color = Red | Green | Blue

fn color_code(c: Color) -> i32:
    match c
        Red -> 0
        Green -> 1
        Blue -> 2

type Pair = {
    first: i32,
    second: i32,
}

fn get_first(p: Pair) -> i32:
    p.first

fn main -> i32:
    let c = Green
    let code = color_code(c)
    let p = Pair { first: 10, second: 20 }
    let f = get_first(p)
    code + f
