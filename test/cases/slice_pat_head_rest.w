//! expect-stdout: first=10
//! expect-stdout: ok
extern fn print(s: str) -> void
extern fn int_to_string(n: i32) -> str

fn main:
    let arr = [10, 20, 30, 40]
    // [first, ..rest] matches any array with at least 1 element
    match arr
        [first, ..rest] => print("first=" ++ int_to_string(first))
        _ => print("no match")
    print("ok")
