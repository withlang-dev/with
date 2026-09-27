//! expect-error: a string slice cannot be returned yet

// #1587: a `&str` today points at a string header, so a range view's header
// lives in the function's own frame; returning it would dangle. Refused by
// name until `&str` carries its own `{ptr, len}`.
fn tail(s: &str) -> &str: s[1..]

fn main:
    print(tail("abc"))
