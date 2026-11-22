//! expect-check-fail: cannot return a view of a temporary value

// #2116 (§21.1): the result is a temporary; there is no place for the
// returned `&str` to view. (It was an internal compiler error: invalid MIR.)
fn f() -> &str: "a".to_upper()

fn main: print(f())
