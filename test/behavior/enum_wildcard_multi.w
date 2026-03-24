//! expect-stdout: blue=other yellow=other
enum Color { Red | Green | Blue | Yellow }

fn describe(c: Color) -> str:
    match c
        .Red => "red"
        .Green => "green"
        _ => "other"

fn main:
    let b = describe(.Blue)
    let y = describe(.Yellow)
    println("blue=" ++ b ++ " yellow=" ++ y)
