// Wave 10: cross-module monomorphization dedup for repeated instantiation.

use mono.shared

fn main -> i32:
    let a = id(1)
    let b = id(2)
    let c = choose_left(3, true)
    assert(a + b + c == 6)
    0
