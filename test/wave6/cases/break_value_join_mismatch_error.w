// Wave 6: break-with-value type mismatch must be rejected.

fn bad(flag: bool) -> i32:
    let out = loop:
        if flag:
            break 1
        else:
            break true
    out

fn main -> i32:
    bad(true)
