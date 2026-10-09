//! expect-check-fail: use of moved value

use std.builtins.print_i32
type Payload {
    values: List[i32],
}

fn main:
    let items: List[Payload] = List.new()
    let value = Payload { values: List.new() }
    items.push(value)
    print_i32(value.values.len() as i32)
