//! expect-stdout: 3
//! expect-stdout: 20
//! expect-stdout: 40
//! expect-stdout: 60
fn main:
    var items: List[i32] = List.new()
    items.push(10)
    items.push(20)
    items.push(30)
    var result: List[i32] = List.new()
    for v in items:
        result.push(v * 2)
    print(int_to_string(result.len()))
    for v in result:
        print(int_to_string(v))
