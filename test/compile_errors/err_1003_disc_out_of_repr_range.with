//! expect-check-fail: discriminant value 300 out of range for u8

// #1003 (§4.4a): an explicit discriminant is checked against the
// representation type it is declared in — every width and signedness, not
// only i8 and i16. `B = 300` in a u8 was accepted, stored as 44, and a
// match on it crashed.

enum U8Big: u8:
    A = 1
    B = 300

fn main:
    print(U8Big.B as i32)
