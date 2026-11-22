//! expect-stdout: 7

use std.builtins.int_to_string
type S { a: str, b: str }

fn mk(a: str) -> S:
    S { a, b: "x" }

fn use1(s: S) -> Result[i64, str]:
    let _ = s.a
    if s.b.contains("x"):
        return Ok(7)
    Err("no")

fn main:
    let src = mk("xyz")
    let v = use1(src).unwrap()
    print(int_to_string(v))
