//! expect-stdout: 24
use std.builtins.write
fn main:
    var items: List[i32] = List.new()
    items.push(1)
    items.push(2)
    items.push(3)
    items.push(4)
    let evens = items.filter(it % 2 == 0)
    for v in evens:
        write(int_to_string(v))
