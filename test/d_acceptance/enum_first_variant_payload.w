//! expect-stdout: val=42

use std.builtins.int_to_string
enum Val { Num(i32) | Empty }

fn extract(v: Val) -> i32:
    match v:
        .Num(n) => n
        .Empty => 0

fn main:
    let x: Val = Num(42)
    let r = extract(x)
    print("val=" ++ int_to_string(r))
