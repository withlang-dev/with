//! expect-stdout: ok
// Spec test: Section 13.4 — No References Across Yield.

gen fn owned_words -> str:
    let first = "hello"
    yield first
    let second = "world"
    yield second

fn test_owned_values_may_cross_yield:
    var iter = owned_words()
    match iter.next():
        Some(word) => assert(word == "hello")
        None => assert(false)
    match iter.next():
        Some(word) => assert(word == "world")
        None => assert(false)
    match iter.next():
        Some(_) => assert(false)
        None => assert(true)

fn main:
    test_owned_values_may_cross_yield()
    print("ok")
