//! expect-stdout: ok

// Comptime differential: Vec construction, mutation, and reduction.

comptime fn vec_battery(n: i32) -> i32:
    var xs = Vec[i32].new()
    for i in 0..n:
        xs.push(i * 3)
    var sum = 0
    for i in 0..xs.len() as i32:
        sum = sum + xs[i as i64]
    let _ = xs.pop()
    sum + xs.len() as i32

const CT_VEC: i32 = comptime vec_battery(17)

fn main:
    assert(CT_VEC == vec_battery(17))
    print("ok")
