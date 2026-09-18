use std.builtins.print
enum Color { Red, Green, Blue }
fn name(c: Color) -> str:
    match c:
        Color.Red => "r"
        Color.Green => "g"
fn main:
    print(name(Color.Blue))
