//! expect-check-fail: `K` is declared as a function and as a global in this module

// #2066: a free function and a module const of one name. The bare name
// meant the function and the const was unreachable: `K()` ran and `K`
// printed nothing.

fn K() -> i32: 1
const K: i32 = 2

fn main:
    print(f"{K}")
