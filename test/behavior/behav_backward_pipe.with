//! expect-stdout: 14 11
// §9.6: backward application `f <| x` desugars to `f(x)`. It is right-associative
// and lower precedence than arithmetic, so `f <| a + b` == `f(a + b)` and
// `f <| g <| x` == `f(g(x))`. (#581: `<|` is implemented; this replaces the old
// "not yet implemented" placeholder.)

fn inc(x: i32) -> i32: x + 1
fn dbl(x: i32) -> i32: x * 2

fn main:
    let a = dbl <| 3 + 4
    let b = inc <| dbl <| 5
    print(f"{a} {b}")
