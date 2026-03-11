//! expect-stdout: 24
fn main:
    var items: Vec[i32] = Vec.new()
    items.push(1)
    items.push(2)
    items.push(3)
    items.push(4)
    let evens = items.filter(x => x % 2 == 0)
    for v in evens:
        print(int_to_string(v))
