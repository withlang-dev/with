//! expect-stdout: hello
fn main:
    let s = "  hello  "
    let trimmed = s.trim()
    println(trimmed)
