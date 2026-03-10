//! expect-stdout: 3
fn double(x: i32) -> i32:
    x * 2

fn main:
    var items: Vec[i32] = Vec.new()
    items.push(10)
    items.push(20)
    items.push(30)
    println(int_to_string(items.len()))
    let doubled = items.map(double)
    println(int_to_string(doubled.len()))
    for v in doubled:
        println(int_to_string(v))
