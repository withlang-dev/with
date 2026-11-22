//! expect-check-fail: an element-count buffer requires a complete element type
//! expect-check-fail: = help: count bytes instead: 'buffer param 0 len param 1' renders []u8

use c_import("static inline int count(const void *values, int n) { return n; }")
c contract counts:
    fn count
        buffer param values len param n elements
fn main: ()
