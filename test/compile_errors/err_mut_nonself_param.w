//! expect-check-fail: `mut` is not a parameter modifier

// #645 / mutability.md: parameters are implicitly rebindable; there is no
// `mut x: T` parameter modifier. `mut self` is valid; `mut` on any other
// parameter is rejected loudly instead of silently discarded.

fn bump(mut x: i32) -> i32:
    x + 1

fn main:
    print_i32(bump(1))
