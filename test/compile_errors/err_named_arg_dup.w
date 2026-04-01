//! expect-error: parameter 'a' specified more than once

fn foo(a: i32, b: i32) -> i32:
    a + b

fn main:
    foo(1, a: 2)
