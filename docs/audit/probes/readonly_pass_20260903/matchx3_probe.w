use std.builtins.print
fn name(b: bool) -> str:
    match b:
        true => "t"
fn main:
    print(name(false))
