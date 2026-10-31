//! expect-error: while condition must be bool

// #654: while conditions must be bool.
fn main:
    var n = "a"
    while n:
        n = ""
