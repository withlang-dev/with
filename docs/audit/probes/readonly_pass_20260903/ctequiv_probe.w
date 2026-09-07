use std.builtins.print_i32
fn fib(n: i32) -> i32:
    if n <= 1: n else: fib(n - 1) + fib(n - 2)
comptime fn cfib(n: i32) -> i32:
    if n <= 1: n else: cfib(n - 1) + cfib(n - 2)
const C = cfib(10)
fn main:
    let r = fib(10)
    print_i32(r)
    print_i32(C)
    print_i32(if r == C: 1 else: 0)
