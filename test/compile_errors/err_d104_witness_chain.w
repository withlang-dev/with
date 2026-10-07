//! expect-check-fail: reached through fib -> helper

// D104 (§17.1): a compile-time call that reaches a forbidden operation
// (here an extern, three calls deep) is refused where the evaluator meets
// it, and the diagnostic names the chain of calls that led there — Zig's
// hole, with a one-line diagnosis instead of a re-derivation. Recursion
// reads as one frame.
extern fn getpid() -> i32

fn helper(n: i32) -> i32: n + getpid()
fn fib(n: i32) -> i32: if n < 2: helper(n) else: fib(n - 1) + fib(n - 2)

const TABLE: i32 = comptime fib(3)

fn main: print(TABLE)
