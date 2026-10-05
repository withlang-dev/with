//! expect-check-fail: returned view may outlive its origin 's'

// #2116 (§21.1): the function returns `&str` and its result is the local
// owned `s`: a view of a value that dies with the frame. It compiled, and
// `s` was never released.
fn dangling() -> &str:
    let s = "local".to_upper()
    s

fn main: print(dangling())
