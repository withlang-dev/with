fn add_one(x: i128): x + 1i128

fn main:
    let x: i128 = 9223372036854775807i128
    let y = add_one(x)
    assert(y > x)
    print("overflow-i128-runtime: ok")
