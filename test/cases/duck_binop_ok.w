//! expect-stdout: 10

fn double[T](x: T) -> T:
    x + x

fn main:
    println(int_to_string(double(5)))
