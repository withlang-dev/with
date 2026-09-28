//! expect-check-fail: use of moved value

// §4.5 (D75, #1802): casting an owned value into its distinct type moves it;
// `s` is gone after `s as Name`. Keep it with `s as &Name` (a view) or
// `s.clone() as Name`. Before, the cast read `s`, both owned the buffer, and
// the program double freed.
type Name = distinct str

fn main:
    let s = "abc".clone()
    let n = s as Name
    print(n as &str)
    print(s)
