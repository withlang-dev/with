//! expect-check-fail: sign '+' requires numeric type
fn main:
    let s = "hello"
    println(f"{s:+}")
