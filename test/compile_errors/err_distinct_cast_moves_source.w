//! expect-check-fail: use of moved value

// §4.5 (D75, #1802): casting an owned value into its distinct type moves it;
// `v` is gone after `v as Items`. Keep it with `v as &Items` (a view) or
// `v.clone() as Items`. Before, the cast read `v`, both owned the buffer, and
// the program double freed. A distinct List, not a distinct str: a str is
// copied (D111).
type Items = distinct List[i32]

fn main:
    let v: List[i32] = [1, 2]
    let n = v as Items
    print((n as &List[i32]).len())
    print(v.len())
