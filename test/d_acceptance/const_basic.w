//! expect-stdout: 100
use std.builtins.int_to_string
const MAX: i32 = 100

fn main:
    print(int_to_string(MAX))
