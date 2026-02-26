fn find(n: i32) -> ?i32:
    if n > 0: Some(n * 10)
    else None

fn main -> i32:
    match find(5)
        Some(v) -> println(v)
        None -> println(0)
    match find(-1)
        Some(v) -> println(v)
        None -> println(0)
    0
