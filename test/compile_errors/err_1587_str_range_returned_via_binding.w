//! expect-error: a string slice cannot be returned yet

// #1587: the same through a binding of the view.
fn tail(s: &str) -> &str:
    let t = s[1..]
    t

fn main:
    print(tail("abc"))
