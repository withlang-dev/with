//! expect-check-fail: missing return

comptime fn maybe(flag: bool) -> i32:
    if flag:
        return 1

const VALUE = comptime maybe(false)

fn main:
    let _ = VALUE
