//! expect-exit: 134
//! expect-stderr: buffer count in elements does not fit the C count type

use c_import("static inline void fill(int *values, signed char *n) { *n = 0; }")
c facade counts:
    fn fill
        buffer param values capacity param n inout elements
fn main:
    var values: [i32; 128] = [1; 128]
    print(f"unexpected: {fill(values)}")
