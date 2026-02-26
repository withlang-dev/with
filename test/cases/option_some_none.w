fn find(n: i32) -> ?i32 =
    if n > 0: Some(n * 10)
    else None

fn main() -> i32 =
    let a = find(5)
    let b = find(-1)
    println(a ?? 0)
    println(b ?? 0)
    println(a.is_some())
    println(b.is_none())
    0
