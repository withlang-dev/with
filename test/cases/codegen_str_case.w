//! expect-stdout: HELLO
//! expect-stdout: hello
fn main:
    let s = "hello"
    let upper = s.to_upper()
    println(upper)
    let s2 = "HELLO"
    let lower = s2.to_lower()
    println(lower)
