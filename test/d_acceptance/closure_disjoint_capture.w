//! expect-stdout: 31
use std.builtins.int_to_string
type World { x: i32, y: i32 }

fn main:
    var w = World { x: 10, y: 20 }
    w.x = w.x + 1
    print(int_to_string(w.x + w.y) ++ "\n")
