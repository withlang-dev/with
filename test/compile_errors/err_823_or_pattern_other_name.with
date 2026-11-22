//! expect-check-fail: alternative 2 of this pattern binds `y`, which the first alternative does not bind (§9.7)

// #823: every alternative binds the same names.
enum E:
    A(n: i32)
    C(n: i32, m: i32)

fn g(e: E) -> i32:
    match e:
        .A(x) | .C(y, _) => x

fn main: print(g(.A(1)))
