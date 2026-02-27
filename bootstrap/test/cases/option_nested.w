// Test nested option operations
fn find_positive(x: i32) -> ?i32:
    if x > 0 then Some(x)
    else None

fn double_positive(x: i32) -> ?i32:
    let opt = find_positive(x)
    match opt
        Some(v) -> Some(v * 2)
        None -> None

fn main -> i32:
    match double_positive(5)
        Some(v) -> println(v)
        None -> println(0)

    match double_positive(-3)
        Some(v) -> println(v)
        None -> println(-1)

    // Test ?? default operator
    let a = find_positive(10) ?? 0
    println(a)

    let b = find_positive(-5) ?? 99
    println(b)
