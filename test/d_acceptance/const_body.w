//! expect-stdout: 42
use std.builtins.int_to_string
fn main:
    const LIMIT: i32 = 42
    print(int_to_string(LIMIT))
