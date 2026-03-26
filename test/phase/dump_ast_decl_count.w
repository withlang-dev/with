//! args: --dump-ast
//! expect-check-stdout: decls=2

fn foo -> i32:
    42

fn main:
    let x = foo()
