// Test: comptime expressions and comptime if
fn main -> i32:
    // comptime arithmetic
    let x = comptime 2 + 3 * 4
    assert(x == 14)

    // comptime if with true condition
    let a = comptime if true then 42 else 99
    assert(a == 42)

    // comptime if with false condition
    let b = comptime if false then 42 else 99
    assert(b == 99)

    // comptime if with comparison
    let c = comptime if 10 > 5 then 1 else 0
    assert(c == 1)

    // comptime if with equality
    let d = comptime if 3 == 3 then 100 else 200
    assert(d == 100)

    // nested comptime arithmetic
    let e = comptime (10 - 3) * 2
    assert(e == 14)

