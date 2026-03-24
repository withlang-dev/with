//! expect-stdout: ok
extern fn print(s: str) -> void
extern fn int_to_string(n: i32) -> str

enum Color: i32 { Red = 1 | Green = 2 | Blue = 4 }

fn main:
    let r = Color.Red
    let g = Color.Green
    let b = Color.Blue
    // Values are the explicit discriminants
    assert(r == 1)
    assert(g == 2)
    assert(b == 4)
    // Can compare against each other
    assert(r == Color.Red)
    assert(g != Color.Red)
    // Arithmetic works since they're integers
    let sum = r + g + b
    assert(sum == 7)
    print("ok")
