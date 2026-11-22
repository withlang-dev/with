//! expect-stdout: ok

// Comptime differential: loops, match, recursion, early return.

comptime fn fib(n: i32) -> i32:
    if n < 2:
        return n
    fib(n - 1) + fib(n - 2)

comptime fn classify(n: i32) -> i32:
    match n % 4:
        0 => 11
        1 => 22
        2 => 33
        _ => 44

comptime fn control_battery(n: i32) -> i32:
    var acc = fib(n)
    var i = 0
    while i < n:
        acc = acc + classify(i)
        i = i + 1
    for j in 0..n:
        if j == 5:
            continue
        if j > 9:
            break
        acc = acc + j
    acc

const CT_CONTROL: i32 = comptime control_battery(12)

fn main:
    assert(CT_CONTROL == control_battery(12))
    print("ok")
