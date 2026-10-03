//! expect-stdout: first=10
//! expect-stdout: ok

fn main:
    let arr = [10, 20, 30, 40]
    // [first, ..rest] matches any array with at least 1 element
    match arr:
        [first, ..rest] => print("first=" ++ int_to_string(first))
        _ => print("no match")
    print("ok")
