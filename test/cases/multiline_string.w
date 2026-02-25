// Test: multi-line strings with triple quotes
fn main() -> i32 =
    let s = """
hello
world
"""
    assert(s.len == 11)
    println(s)
    0
