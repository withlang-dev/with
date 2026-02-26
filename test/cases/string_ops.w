// Test string operations
fn main -> i32:
    let s = "Hello, World!"
    println(s.len())
    println(s.contains("World"))
    println(s.starts_with("Hello"))
    println(s.ends_with("!"))
    println(s.to_upper())
    println(s.to_lower())
