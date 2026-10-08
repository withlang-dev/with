//! expect-check-fail: use of moved value

// §4.5 (D75, #1802): casting an owned value into its distinct type moves it;
// `v` is gone after `v as Items`. Keep it with `v as &Items` (a view) or
// `v.clone() as Items`. Before, the cast read `v`, both owned the buffer, and
// the program double freed. A distinct Vec, not a distinct str: a str is
// copied (D111).
type Items = distinct Vec[i32]

fn main:
    let v: Vec[i32] = [1, 2]
    let n = v as Items
    print((n as &Vec[i32]).len())
    print(v.len())
