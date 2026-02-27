// POSITIVE: match on str values uses strcmp-based chain (§9.7)
fn classify(s: str) -> i32:
    match s
        "hello" -> 1
        "world" -> 2
        "foo" -> 3
        _ -> 0

fn main -> i32:
    assert(classify("hello") == 1)
    assert(classify("world") == 2)
    assert(classify("foo") == 3)
    assert(classify("bar") == 0)
    println("match string ok")
