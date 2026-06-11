//! expect-check-fail: missing return

fn maybe(flag: bool) -> i32:
    if flag:
        return 1

fn main:
    let _ = maybe(false)
