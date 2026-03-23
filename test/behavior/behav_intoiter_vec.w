//! expect-stdout: 15

fn main:
    let v: Vec[i32] = Vec.new()
    v.push(1)
    v.push(2)
    v.push(3)
    v.push(4)
    v.push(5)
    var sum = 0
    for x in v.iter():
        sum = sum + x
    print(int_to_string(sum as i64))
