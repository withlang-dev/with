//! expect-stdout: 20
fn double(x: i32) -> i32:
    x * 2

fn main:
    var items: Vec[i32] = Vec.new()
    items.push(10)
    items.push(20)
    let r1 = items.map(double)
    for v in r1:
        println(int_to_string(v))
