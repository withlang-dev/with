//! expect-error: alignment exceeds maximum 65536

type S {
    @[align(131072)] x: i32,
}

fn main:
    print("x")
