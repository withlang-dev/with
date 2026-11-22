//! expect-check-fail: non-exhaustive match on 'i32': `-1` is not covered

// #994 / #1388 (§9.7): an expression-position match over an integer with
// no catch-all used to fall through and return an uninitialised value.

fn f(n: i32) -> str:
    match n:
        0 => "zero"
        1 => "one"

fn main:
    print(f(2))
