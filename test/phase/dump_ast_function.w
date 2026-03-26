//! args: --dump-ast
//! expect-check-stdout: kind=function

fn add(a: i32, b: i32) -> i32:
    a + b

fn main:
    let r = add(1, 2)
