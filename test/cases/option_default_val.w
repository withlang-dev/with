fn find_positive(n: i32) -> ?i32 =
    if n > 0: Some(n)
    else None

fn main() -> i32 =
    let a = find_positive(42) ?? 0
    let b = find_positive(-5) ?? 99
    let c = find_positive(0) ?? -1
    println(a)
    println(b)
    println(c)
    0
