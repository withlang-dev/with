//! expect-stdout: 210
use std.builtins.int_to_string
const WIDTH: i32 = 10
const HEIGHT: i32 = 21
const AREA: i32 = WIDTH * HEIGHT

fn main:
    print(int_to_string(AREA))
