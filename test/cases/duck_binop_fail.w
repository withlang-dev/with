//! expect-build-fail: unsupported operator

fn double[T](x: T) -> T:
    x + x

fn main:
    let s = double("hi")
