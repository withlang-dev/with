//! expect-error: the auto-incremented discriminant of variant `C` is past the range of i32: the variant before it, `B`, is 2147483647

// #1452 (§4.4a): auto-increment gives a variant the previous value plus one;
// past the repr's maximum there is no such value. (A last variant at the
// maximum is fine: the compiler once panicked incrementing after it.)

enum K: i32:
    A = 1
    B = 2147483647
    C

fn main:
    print(K.A as i32)
