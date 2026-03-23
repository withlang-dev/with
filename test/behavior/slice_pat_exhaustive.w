//! expect-stdout: three: 6
//! expect-stdout: first: 1
//! expect-stdout: 1 to 3
//! expect-stdout: ok
extern fn print(s: str) -> void
extern fn int_to_string(n: i32) -> str

fn main:
    let arr = [1, 2, 3]
    // Exhaustive: exact element count match for [3]i32
    let r1 = match arr
        [a, b, c] => "three: " ++ int_to_string(a + b + c)
    print(r1)

    // Exhaustive: head + rest covers all arrays of length >= 1
    let r2 = match arr
        [first, ..rest] => "first: " ++ int_to_string(first)
    print(r2)

    // Exhaustive: both ends extraction
    let r3 = match arr
        [first, ..mid, last] => int_to_string(first) ++ " to " ++ int_to_string(last)
    print(r3)

    print("ok")
