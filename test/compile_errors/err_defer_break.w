//! expect-check-fail: break not allowed in defer

fn bad_break:
    while true:
        defer:
            break
