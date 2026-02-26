// Test single-variant enum
type Wrapper = | Value(i32)

fn unwrap(w: Wrapper) -> i32 =
    match w
        Value(n) -> n

fn main() -> i32 =
    let w = Value(42)
    println(unwrap(w))
    0
