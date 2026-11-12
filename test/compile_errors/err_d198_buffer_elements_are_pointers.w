//! expect-check-fail: an element-count buffer's elements are flat, and the element
// D198 (§16.2b.5, §16.2b.8): a slice of raw pointers hands C addresses safe code chose.
use c_import("static inline int first_of(const int *const *ps, int count) { return count > 0 ? *ps[0] : 0; }")

c contract firsts:
    fn first_of
        buffer param ps len param count elements

fn main:
    print("unreachable")
