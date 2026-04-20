//! expect-stdout: 369
fn main:
    var items: Vec[i32] = Vec.new()
    items.push(1)
    items.push(2)
    items.push(3)
    let tripled = items.map(it * 3)
    for v in tripled:
        write(int_to_string(v))
