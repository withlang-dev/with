//! expect-check-fail: wrong argument type in call to 'g'

// #1711: the same float-accepts-anything answer let a `str` argument reach
// an `f64` parameter; codegen then refused it with no source location.

fn g(x: f64): x
fn main:
    print(f"{g("s")}")
