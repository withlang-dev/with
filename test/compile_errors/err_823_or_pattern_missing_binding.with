//! expect-check-fail: alternative 2 of this pattern does not bind `x`, which the first alternative binds (§9.7)
//! expect-check-fail: = help: every alternative binds the same names; write `_` in the first alternative if the arm does not use it

// #823: the arm reads `x`, and the second alternative gives it no value.
enum E:
    A(n: i32)
    B(s: str)

fn f(e: E) -> i32:
    match e:
        .A(x) | .B(_) => x

fn main: print(f(.A(1)))
