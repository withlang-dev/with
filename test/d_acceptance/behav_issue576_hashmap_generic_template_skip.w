//! expect-stdout: 1

use std.collections.HashMap
use std.builtins.int_to_string
fn main:
    var m = HashMap[str, i32].new()
    m.insert("a", 1)
    print(int_to_string(m.len()))
