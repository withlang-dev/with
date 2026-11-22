//! expect-stdout: ok

// Comptime differential: List construction, mutation, and reduction.

comptime fn list_battery(n: i32) -> i32:
    var xs = List[i32].new()
    for i in 0..n:
        xs.push(i * 3)
    var sum = 0
    for i in 0..xs.len() as i32:
        sum = sum + xs[i as i64]
    let _ = xs.pop()
    sum + xs.len() as i32

const CT_LIST: i32 = comptime list_battery(17)

fn main:
    assert(CT_LIST == list_battery(17))
    print("ok")
