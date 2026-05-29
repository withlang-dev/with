//! expect-check-fail: continue not allowed in defer

fn bad_continue:
    while true:
        defer:
            continue
