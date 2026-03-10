//! expect-stdout: first=10 last=50
//! expect-stdout: ok
extern fn print(s: str) -> void
extern fn int_to_string(n: i32) -> str

fn main:
    let arr = [10, 20, 30, 40, 50]
    // [first, ..middle, last] — extract both ends
    match arr
        [first, ..middle, last] -> print("first=" ++ int_to_string(first) ++ " last=" ++ int_to_string(last))
        _ -> print("no match")
    print("ok")
