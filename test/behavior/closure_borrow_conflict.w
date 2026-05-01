//! expect-error: `&mut` is not part of safe With
fn run_both(f: fn(i32) -> i32, g: fn(i32) -> i32) -> i32: f(0) + g(0)

fn inc(p: &mut i32) -> i32:
    *p = *p + 1
    *p

fn main:
    var total = 0
    let r = run_both(x => inc(&mut total), x => total + x)
