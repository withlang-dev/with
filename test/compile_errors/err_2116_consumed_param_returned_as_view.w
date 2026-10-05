//! expect-check-fail: returned view may outlive its origin 's'

// #2116 (§21.1, §3.8): a plain `str` parameter is consumed, so it dies when
// the function returns; returning it as `&str` is a view of a dead value.
fn f(s: str) -> &str: s

fn main: print(f("x".to_upper()))
