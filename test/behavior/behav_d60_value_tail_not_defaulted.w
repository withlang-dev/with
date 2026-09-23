//! expect-stdout: 5 5
//! expect-stdout: 5 false
//! expect-stdout: 0 true

// §4.10: "The implicit default applies only when the tail's own type is
// `Unit`. ... The compiler never discards a tail's value to substitute
// `T.default()`." A str's `.len` is a value of type i64; MIR has no place
// type for the projection, and the fn body decided the default by the
// lowered operand's type, so these bodies returned 0 (std.string.view_len
// among them). The body's type decides.

use std.string.view_len
use std.string.view_is_empty

fn borrowed_len(v: &str) -> i64: v.len
fn owned_len(v: str) -> i64: v.len

fn main:
    let s = "abc".clone() ++ "de"
    print(f"{borrowed_len(&s)} {owned_len(s.clone())}")
    print(f"{view_len(&s)} {view_is_empty(&s)}")
    let e = ""
    print(f"{view_len(e)} {view_is_empty(e)}")
