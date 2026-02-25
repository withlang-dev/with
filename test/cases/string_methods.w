// Test: String methods
fn main() -> i32 =
    let s = "hello world"

    // .len()
    assert(s.len() == 11)

    // .is_empty()
    assert(not s.is_empty())
    let empty_str = ""
    assert(empty_str.is_empty())

    // .contains()
    assert(s.contains("world"))
    assert(s.contains("hello"))
    assert(not s.contains("xyz"))

    // .starts_with()
    assert(s.starts_with("hello"))
    assert(not s.starts_with("world"))

    // .ends_with()
    assert(s.ends_with("world"))
    assert(not s.ends_with("hello"))

    // .find()
    assert(s.find("world") == 6)
    assert(s.find("xyz") == 0 - 1)

    // .slice()
    let sub = s.slice(0, 5)
    assert(sub.len() == 5)
    assert(sub.starts_with("hello"))

    // .to_upper() / .to_lower()
    let abc = "abc"
    let upper = abc.to_upper()
    assert(upper.starts_with("ABC"))
    let xyz = "XYZ"
    let lower = xyz.to_lower()
    assert(lower.starts_with("xyz"))

    // .repeat()
    let ab = "ab"
    let rep = ab.repeat(3)
    assert(rep.len() == 6)
    assert(rep.starts_with("ababab"))

    // .replace()
    let r = s.replace("world", "there")
    assert(r.contains("there"))
    assert(not r.contains("world"))

    println("all string method tests passed")
    0
