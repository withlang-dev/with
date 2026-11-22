//! expect-check-fail: use of moved value

// #1380 (§2.2): a value `match` arm that yields a whole binding moves it,
// like an `if` arm and like `let p = a`.
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
use std.process

fn main:
    var xs: List[Tok] = List.new()
    xs.push(Tok { id: 1 })
    let ys: List[Tok] = List.new()
    let p = match args().len() > 0:
        true => xs
        false => ys
    print(f"{p.len()} {xs.len()}")
