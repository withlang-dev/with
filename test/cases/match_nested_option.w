// Test nested option matching
fn safe_div(a: i32, b: i32) -> ?i32 =
    if b == 0: None
    else Some(a / b)

fn safe_sqrt(n: i32) -> ?i32 =
    if n < 0: None
    else if n == 0: Some(0)
    else Some(n)

fn main() -> i32 =
    match safe_div(10, 2)
        Some(v) -> match safe_sqrt(v)
            Some(r) -> println(r)
            None -> println(-1)
        None -> println(-2)
    match safe_div(10, 0)
        Some(v) -> println(v)
        None -> println(-2)
    0
