//! expect-check-fail: break not allowed in defer [E0901]

fn bad_break:
    while true:
        defer:
            break
