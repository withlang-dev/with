//! expect-check-fail: remove() index out of bounds in comptime

comptime fn remove_oob() -> i32:
    var v = Vec[i32].new()
    v.push(10)
    v.push(20)
    v.push(30)
    v.remove(10)

fn main:
    let bad: i32 = comptime remove_oob()
    assert(bad == 0)
