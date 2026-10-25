//! expect-exit: 134
//! expect-stdout: 99
//! expect-stderr: str.byte_at index out of bounds
// #996 (D71): byte_at outside the string panics, as a List index does. It
// returned 0, a NUL byte, for any position past the end or before 0; the
// comptime evaluator already refused the same call.
fn main:
    let s = "abc"
    print(s.byte_at(2))
    print(s.byte_at(99))
