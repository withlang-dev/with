//! expect-check-fail: cannot infer return type: if arms have types i32 and Unit; add `-> i32` or `-> Unit`

// D43 (#1178): every arm is written and they do not unify. The compiler does
// not pick Unit, the first arm, or a fabricated value.

fn bump(x: i32) -> i32: x + 1
fn f(p: bool):
    if p: bump(1)
    else: print("no")

fn main: f(true)
