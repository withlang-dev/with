//! expect-error: the doubled (@[flags]) discriminant of variant `B` is past the range of u8: the variant before it, `A`, is 128

// #1452 (§4.4a): under @[flags] auto-increment doubles; 256 is not a u8. The
// compiler accepted it and B read back as 0.

@[flags]
enum E: u8:
    A = 128
    B

fn main:
    print(E.B as u8)
