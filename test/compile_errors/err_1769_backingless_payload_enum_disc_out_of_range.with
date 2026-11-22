//! expect-check-fail: discriminant value 3000000000 out of range for i32

// #1769 (§4.4a): a backing-less enum with a payload variant and an explicit
// `= N` is a discriminant enum in the inferred i32, so a value past i32 is
// refused — the width default is visible, not a silent truncation (#1003).

enum M:
    A = 3000000000
    B(i32)

fn main:
    print(M.A as i32)
