//! expect-error: issue155 called generic

fn fail[T](x: T) -> i32:
    comptime_error("issue155 called generic")

fn main:
    let x = fail(1)
    print("{x}")
