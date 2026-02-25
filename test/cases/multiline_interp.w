// Test: Multiline string literals
fn main() -> i32 =
    let s = "hello\nworld"
    assert(s.len() == 11)
    0
