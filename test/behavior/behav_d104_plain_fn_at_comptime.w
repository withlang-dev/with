//! expect-stdout: 144 55
//! expect-stdout: 12

// D104 (§17.1): a plain function runs at compile time when a compile-time
// call reaches it; nothing marks it. `fib` is one function, used at both
// times; `sum_to` reaches `square` through an ordinary call.
fn fib(n: i32) -> i32: if n < 2: n else: fib(n - 1) + fib(n - 2)
fn square(x: i32) -> i32: x * x
fn sum_to(n: i32) -> i32:
    var total: i32 = 0
    for i in 1..n + 1: total += square(i)
    total

const TABLE: i32 = comptime fib(12)
const SQUARES: i32 = comptime sum_to(2)

fn main:
    print(f"{TABLE} {fib(10)}")
    print(SQUARES + comptime square(2) + sum_to(1) + 2)
