//! expect-check-fail: return type mismatch

// §4.5 (D75, #1802): a cast through a reference borrows and yields a view —
// `r as str` with `r: &Name` is a `&str`, never an owned `str` (that would
// be a second owner of the caller's buffer). An owned result is spelled
// `(r as str).clone()`.
type Name = distinct str

fn owned(r: &Name) -> str: r as str

fn main:
    let n = "abc".clone() as Name
    print(owned(n))
