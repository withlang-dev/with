//! expect-error: alignment must be a power of two

type S {
    @[align(3)] x: i32,
}

fn main:
    print("x")
