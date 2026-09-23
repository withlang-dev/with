//! expect-check-fail: return type mismatch

// §9.1 / §4.10 / D60: a tail assignment under a declared non-Unit return is
// the body's value — a read of `g`, an i32 — so `-> str` is a type error.
// The implicit default applies only to a Unit tail; #1319 returned
// `str.default()` here with no diagnostic.

var g: i32 = 5
fn f -> str: g += 1

fn main: print(f())
