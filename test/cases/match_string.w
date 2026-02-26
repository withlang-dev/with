// Test match on string values
fn classify(s: str) -> i32 =
    match s
        "hello" -> 1
        "world" -> 2
        "foo" -> 3
        _ -> 0

fn main() -> i32 =
    println(classify("hello"))
    println(classify("world"))
    println(classify("foo"))
    println(classify("bar"))
    println(classify(""))
    0
