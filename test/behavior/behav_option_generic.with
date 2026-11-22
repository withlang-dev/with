//! expect-stdout: 5
use std.builtins.int_to_string
fn main:
    let x: Option[i32] = Some(5)
    let val = match x:
        .Some(n) => n
        .None => -1
    print(int_to_string(val))
