// Test: string with escape sequences \n \t \\ \"
fn main() -> i32 =
    let s1 = "hello\tworld"
    assert(s1.len == 11)

    let s2 = "line1\nline2"
    assert(s2.len == 11)

    let s3 = "quote: \""
    assert(s3.len == 8)

    let s4 = "back\\slash"
    assert(s4.len == 10)

    let s5 = "a\tb\nc"
    assert(s5.len == 5)

    0
