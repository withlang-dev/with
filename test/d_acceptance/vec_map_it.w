//! expect-stdout: 369
use std.builtins.int_to_string
fn main:
    var items: List[i32] = List.new()
    items.push(1)
    items.push(2)
    items.push(3)
    let tripled = items.map(it * 3)
    for v in tripled:
        write(int_to_string(v))
