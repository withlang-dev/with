//! expect-stdout: 3
//! expect-stdout: 3
//! expect-stdout: 20
//! expect-stdout: 40
//! expect-stdout: 60
use std.builtins.int_to_string
fn double(x: i32) -> i32:
    x * 2

fn main:
    var items: List[i32] = List.new()
    items.push(10)
    items.push(20)
    items.push(30)
    print(int_to_string(items.len()))
    let doubled = items.map(double)
    print(int_to_string(doubled.len()))
    for v in doubled:
        print(int_to_string(v))
