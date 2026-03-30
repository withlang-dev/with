//! expect-stdout: 3
fn main:
    var items: Vec[i32] = Vec.new()
    items.push(10)
    items.push(20)
    items.push(30)
    var result: Vec[i32] = Vec.new()
    for v in items:
        result.push(v * 2)
    print(int_to_string(result.len()))
    for v in result:
        print(int_to_string(v))
