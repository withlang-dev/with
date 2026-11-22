//! expect-stdout: ok

// Behavior test: @ binding patterns in match expressions

fn describe(n: i32) -> i32:
    match n:
        x @ 1 => x + 100
        y @ 2 => y + 200
        _ => 0

fn main:
    assert(describe(1) == 101)
    assert(describe(2) == 202)
    assert(describe(3) == 0)
    print("ok")
