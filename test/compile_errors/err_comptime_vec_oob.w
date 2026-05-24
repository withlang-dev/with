//! expect-check-fail: index out of bounds in comptime

comptime fn oob_access() -> i32:
    var v = Vec[i32].new()
    v.push(10)
    v.push(20)
    v.push(30)
    v.get(5)

fn main:
    let bad: i32 = comptime oob_access()
    assert(bad == 0)
