//! expect-stdout: hello world
fn main:
    let s = "hello there"
    let replaced = s.replace("there", "world")
    println(replaced)
