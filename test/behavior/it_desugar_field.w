//! expect-stdout: 246
fn main:
    var items: Vec[i32] = Vec.new()
    items.push(1)
    items.push(2)
    items.push(3)
    let doubled = items.map(it * 2)
    for v in doubled:
        write(int_to_string(v))
