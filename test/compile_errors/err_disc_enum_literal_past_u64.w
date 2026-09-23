//! expect-error: discriminant of variant `A` does not fit u64

// #1452 (§4.4a): 2^64 is no u64 value.

enum E: u64:
    A = 18446744073709551616

fn main:
    print(E.A as u64)
