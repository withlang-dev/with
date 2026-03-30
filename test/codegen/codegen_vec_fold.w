//! expect-stdout: 10
fn main:
    let v: Vec[i32] = Vec.new()
    v.push(1)
    v.push(2)
    v.push(3)
    v.push(4)
    let sum = v.fold(0, (acc, x) => acc + x)
    print(int_to_string(sum))
