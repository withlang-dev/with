//! expect-error: cannot use unsafe fn where a safe function type is expected

// §16.11 (#1829): an unsafe fn may not coerce to a safe `fn` type — the
// check ran only for an expected `extern "C" fn`.

unsafe fn danger(x: i32) -> i32: x + 1

fn apply(g: fn(i32) -> i32, x: i32) -> i32: g(x)

fn main:
    print(apply(danger, 1))
