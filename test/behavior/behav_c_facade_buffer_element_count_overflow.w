//! expect-exit: 134
//! expect-stderr: buffer count in elements does not fit the C count type

// Conversion must fail before C receives a truncated count.
use c_import("static inline int count(const int *values, unsigned char n) { return n; }")
c facade counts:
    fn count
        buffer param values len param n elements
fn main:
    let values: [i32; 256] = [1; 256]
    print(count(values))
