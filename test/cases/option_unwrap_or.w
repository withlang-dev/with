// Test Option unwrap_or and related methods
fn find_positive(n: i32) -> ?i32:
    if n > 0: Some(n)
    else None

fn main -> i32:
    // unwrap_or via ??
    let a = find_positive(5) ?? 0
    let b = find_positive(-3) ?? 99
    println(a)
    println(b)
    // is_some / is_none
    let c = find_positive(1)
    let d = find_positive(-1)
    println(c.is_some())
    println(d.is_none())
