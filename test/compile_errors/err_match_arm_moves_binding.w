//! expect-check-fail: use of moved value

// #1380 (§2.2): a value `match` arm that yields a whole binding moves it,
// like an `if` arm and like `let p = a`.
use std.process

fn main:
    var xs: Vec[i32] = Vec.new()
    xs.push(1)
    let ys: Vec[i32] = Vec.new()
    let p = match args().len() > 0:
        true => xs
        false => ys
    print(f"{p.len()} {xs.len()}")
