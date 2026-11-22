//! expect-check-fail: not in tail position
// §9: a @[tailrec] fn's bare recursive call inside a while body is NOT in tail
// position (its result is discarded, the loop continues) — must be rejected.
use std.builtins.print_i32
@[tailrec]
fn count(n: i32) -> i32:
    while n > 0:
        count(n - 1)
    0
fn main:
    print_i32(count(3))
