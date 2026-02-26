// Test Option methods
fn main() -> i32 =
    let a: ?i32 = Some(10)
    let b: ?i32 = None
    println(a.is_some())
    println(a.is_none())
    println(b.is_some())
    println(b.is_none())
    println(a.unwrap())
    0
