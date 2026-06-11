//! expect-check-fail: operator 'in' is non-associative; parenthesize the expression

fn main:
    let a = 1
    let b = [1]
    let c = [[1]]
    let _x = a in b in c
