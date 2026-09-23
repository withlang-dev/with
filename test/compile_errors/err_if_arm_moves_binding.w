//! expect-check-fail: use of moved value

// #1380 (§2.2): a value `if` whose arm is a whole binding yields that
// binding by value — MIR moves it into the join (reset-on-move blanks the
// source) exactly as `let p = a` does. The second read used to compile and
// print "" silently.
use std.process

fn main:
    let a = "x" ++ "y"
    let b = "u" ++ "v"
    let c = args().len() > 0
    let p = if c: a else: b
    let q = if c: a else: b
    print(f"[{p}] [{q}]")
