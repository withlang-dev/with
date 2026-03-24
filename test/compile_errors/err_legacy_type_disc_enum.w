//! expect-error: use 'enum' for enum declarations
type Color: i32 = Red = 1 | Green = 2 | Blue = 4

fn main:
    let _ = Color.Green
