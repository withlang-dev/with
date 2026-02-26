// Method calls on string literals
fn main -> i32:
    // .len() on string literal
    let n = "hello".len()
    assert(n == 5)

    // .len() on bound string works too
    let s = "world"
    assert(s.len() == 5)

    // Empty string literal
    assert("".len() == 0)

