//! args: --dump-ast
//! expect-check-stdout: if

fn main:
    let x = 10
    if x > 5:
        println("big")
    else:
        println("small")
