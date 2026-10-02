//! expect-stdout: 5

use std.builtins.int_to_string
fn get_len[T](x: T) -> i32:
    x.len()

fn main:
    print(int_to_string(get_len("hello")))
