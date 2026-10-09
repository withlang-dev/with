//! expect-stdout: 246
use std.builtins.int_to_string
fn main:
    var items: List[i32] = List.new()
    items.push(1)
    items.push(2)
    items.push(3)
    let doubled = items.map(x => x * 2)
    for v in doubled:
        write(int_to_string(v))
