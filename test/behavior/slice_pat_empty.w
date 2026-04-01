//! expect-stdout: matched empty
//! expect-stdout: has elements
//! expect-stdout: ok

fn check_empty(arr: [0]i32) -> str:
    match arr
        [] => "matched empty"
        _ => "no match"

fn main:
    let empty: [0]i32 = []
    print(check_empty(empty))
    // Non-empty array uses different match
    let full = [1, 2, 3]
    let r = match full
        [a, b, c] => "has elements"
        _ => "other"
    print(r)
    print("ok")
