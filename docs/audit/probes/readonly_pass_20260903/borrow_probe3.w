use std.builtins.print
fn leak() -> &str:
    let s = "local"
    &s
fn main:
    print(*leak())
