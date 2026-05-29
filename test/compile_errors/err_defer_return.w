//! expect-check-fail: return not allowed in defer

fn bad_return -> i32:
    defer:
        return 42
    0
