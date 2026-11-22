//! expect-check-fail: E0921: mutation of global `hits` may race

// #3178 (§9.1 rule 3): coercing a With function to an 'extern "C"' callback
// ends the single-thread proof, and a function a header defines is C all
// the same: it may hand the callback to code that keeps it. Only a call of
// a declared-only C function counted before.
use c_import("static inline int apply(int (*f)(int), int x) { return f ? f(x) : -1; }\n")

c contract lib:
    fn apply
        callback param 0

var hits = 0
fn twice(x: c_int) -> c_int:
    hits = hits + 1
    x * 2

fn main:
    print(apply(twice, 21))
    print(hits)
