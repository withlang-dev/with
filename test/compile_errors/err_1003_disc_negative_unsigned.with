//! expect-check-fail: discriminant value -1 out of range for u32

// #1003 (§4.4a): a negative discriminant in an unsigned representation is
// refused; it wrapped to 4294967295 and no match arm fired.

enum U32Neg: u32:
    A = 1
    B = -1

fn main:
    print(U32Neg.B as i64)
