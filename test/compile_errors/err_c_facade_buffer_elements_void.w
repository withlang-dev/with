//! expect-check-fail: an element-count buffer requires a complete element type

use c_import("static inline int count(const void *values, int n) { return n; }")
c facade counts:
    fn count
        buffer param values len param n elements
fn main: ()
