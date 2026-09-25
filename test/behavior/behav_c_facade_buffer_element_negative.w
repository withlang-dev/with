//! expect-exit: 134
//! expect-stderr: C reported -1 elements written into a buffer of 3 elements

use c_import("static inline void fill(int *dest, int *count) { *count = -1; }")
c facade bounds:
    fn fill
        buffer param dest capacity param count inout elements
fn main:
    var output: [i32; 3] = [0; 3]
    print(f"unexpected: {fill(output)}")
