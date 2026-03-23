//! expect-stdout: ok
extern fn print(s: str) -> void
extern fn int_to_string(n: i32) -> str

type Color: i32 = Red = 1 | Green = 2 | Blue = 4

fn main:
    // Field access construction
    let c = Color.Green
    let r = match c
        .Red => "red"
        .Green => "green"
        .Blue => "blue"
        _ => "unknown"
    assert(r == "green")

    // Shorthand construction
    let c2: Color = .Blue
    let r2 = match c2
        .Red => "r"
        .Green => "g"
        .Blue => "b"
        _ => "?"
    assert(r2 == "b")

    // Wildcard catches non-matched
    let c3 = Color.Blue
    let r3 = match c3
        .Red => "r"
        _ => "other"
    assert(r3 == "other")

    // as repr_type cast
    let n: i32 = Color.Green as i32
    assert(n == 2)
    let n2: i32 = c2 as i32
    assert(n2 == 4)

    print("ok")
