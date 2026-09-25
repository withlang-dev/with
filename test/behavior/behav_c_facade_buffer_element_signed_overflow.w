//! expect-exit: 134
//! expect-stderr: buffer count in elements does not fit the C count type

use c_import("static inline int count(const int *values, signed char n) { return n; }")
c facade counts:
    fn count
        buffer param values len param n elements
fn main:
    let values: [i32; 128] = [1; 128]
    print(count(values))
