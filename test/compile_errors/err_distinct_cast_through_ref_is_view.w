//! expect-check-fail: return type mismatch

// §4.5 (D75, #1802): a cast through a reference borrows and yields a view —
// `r as Vec[i32]` with `r: &Items` is a `&Vec[i32]`, never an owned value
// (that would be a second owner of the caller's buffer). An owned result is
// spelled `(r as Vec[i32]).clone()`. A distinct Vec, not a distinct str: a
// str view meets an owned demand with a copy (D111).
type Items = distinct Vec[i32]

fn owned(r: &Items) -> Vec[i32]: r as Vec[i32]

fn main:
    let v: Vec[i32] = [1, 2]
    let n = v as Items
    print(owned(n).len())
