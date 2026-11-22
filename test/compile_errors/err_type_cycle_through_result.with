//! expect-error: dependency loop with length 1

// #1439: Result[E, i32] holds E by value.
enum E:
    A(r: Result[E, i32])
    B

fn main:
    print(1)
