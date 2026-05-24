//! expect-check-fail: pop() on empty comptime vector

comptime fn pop_empty() -> i32:
    var v = Vec[i32].new()
    v.pop()

fn main:
    let bad: i32 = comptime pop_empty()
    assert(bad == 0)
