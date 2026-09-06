use std.builtins.print
fn classify(x: i32) -> str:
    match x:
        0 => "zero"
        1 => "one"
fn main:
    print(classify(2))
