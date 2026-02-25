// Test: built-in string methods
fn main() -> i32 =
    let s = "Hello, World!"

    // len
    assert(s.len() == 13)

    // is_empty
    assert(not s.is_empty())
    let empty = ""
    assert(empty.is_empty())

    // contains
    assert(s.contains("World"))
    assert(not s.contains("xyz"))

    // starts_with / ends_with
    assert(s.starts_with("Hello"))
    assert(not s.starts_with("World"))
    assert(s.ends_with("World!"))
    assert(not s.ends_with("Hello"))

    // find
    assert(s.find("World") == 7)
    assert(s.find("xyz") == -1)
    assert(s.find("Hello") == 0)

    // to_upper / to_lower
    let hello = "hello"
    let up = hello.to_upper()
    assert(up == "HELLO")
    let upper_str = "HELLO"
    let lo = upper_str.to_lower()
    assert(lo == "hello")

    // trim
    let padded = "  hello  "
    let trimmed = padded.trim()
    assert(trimmed == "hello")

    // repeat
    let ab = "ab"
    let r = ab.repeat(3)
    assert(r == "ababab")

    // slice
    let sub = s.slice(0, 5)
    assert(sub == "Hello")

    0
