//! expect-error: the auto-incremented discriminant of variant `B` is past the range of u64: the variant before it, `A`, is 18446744073709551615

// #1452 (§4.4a): u64::MAX + 1 is not a u64.

enum E: u64:
    A = 18446744073709551615
    B

fn main:
    print(E.A as u64)
