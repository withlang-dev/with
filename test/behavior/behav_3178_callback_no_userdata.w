//! expect-stdout: 42
//! expect-stdout: 22

// #3178 (§16.2b.9): 'callback param N' describes a callback that has no
// userdata parameter. It carries no state, so nothing is owned, freed or
// left dangling: a function passes, and so does a closure that captures
// nothing.
use c_import("static inline int apply(int (*f)(int), int x) { return f ? f(x) : -1; }\n")

c contract lib:
    fn apply
        callback param 0

fn twice(x: c_int) -> c_int: x * 2

fn main:
    print(apply(twice, 21))
    print(apply((x) => x + 1, 21))
