//! expect-check-fail: capturing closure cannot coerce to extern "C" fn pointer

// #3178 (§16.2b.9): with no userdata parameter a closure has nowhere to
// keep what it captures, so one that captures is refused.
use c_import("static inline int apply(int (*f)(int), int x) { return f ? f(x) : -1; }\n")

c contract lib:
    fn apply
        callback param 0

fn main:
    let k = 3
    print(apply((x) => x * k, 21))
