//! expect-stdout: ok

comptime fn fib(n: i32) -> i32:
    if n < 2:
        n
    else:
        fib(n - 1) + fib(n - 2)

const FIB7: i32 = comptime fib(7)
const MIXED: i32 = comptime (3 + 4 * 2) - 5

fn main:
    let local_sum: i32 = comptime 10 + 20 + 12
    assert(FIB7 == 13)
    assert(MIXED == 6)
    assert(local_sum == 42)
    println("ok")
