//! expect-build-fail: Integer arithmetic operators only work with integral types

fn double[T](x: T) -> T:
    x + x

fn main:
    let s = double("hi")
