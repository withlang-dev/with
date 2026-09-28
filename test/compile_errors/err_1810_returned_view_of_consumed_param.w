//! expect-error: returned view may outlive its origin 's'

// #1810: a range view carries its base's origin (D71 §4.8a, §21.1 Rule 6).
// A consuming `str` parameter dies when the call returns, so a view of it
// cannot be returned — the `{ptr, len}` would name freed bytes.
fn tail(s: str) -> &str: s[1..]

fn main:
    print(tail("abc"))
