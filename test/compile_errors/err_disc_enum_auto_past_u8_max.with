//! expect-error: the auto-incremented discriminant of variant `B` is past the range of u8: the variant before it, `A`, is 255

// #1452 (§4.4a): 255 + 1 is not a u8. The compiler accepted it and B read
// back as 0.

enum E: u8:
    A = 255
    B

fn main:
    print(E.B as u8)
