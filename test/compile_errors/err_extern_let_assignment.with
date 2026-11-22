//! expect-check-fail: cannot assign to immutable variable

// §16.3: an extern "C" let is an immutable binding to a C global; assigning to
// it is a compile error.

extern "C" let ERRNO_LIKE: i32

fn main:
    ERRNO_LIKE = 3
    print("no")
