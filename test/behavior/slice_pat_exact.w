//! expect-stdout: 10 20 30
//! expect-stdout: ok

fn main:
    let arr = [10, 20, 30]
    // Exact match: [a, b, c] matches [3 x i32]
    match arr:
        [a, b, c] => print(int_to_string(a) ++ " " ++ int_to_string(b) ++ " " ++ int_to_string(c))
        _ => print("no match")
    // Size mismatch: [a, b] does not match [3 x i32]
    let r = match arr:
        [a, b] => "two"
        _ => "other"
    assert(r == "other")
    print("ok")
