//! expect-stdout: ok

// #1362: a public std declaration keeps resolving with no import when a
// program named it before the engine leak closed. is_alnum resolved only
// because the pcre2 corpus's interface (std.re.defs) declared it too and was
// reachable over the prelude edge. Engine corpora are never ambient (§18.2),
// so that twin is gone; the call binds std.string's is_alnum, the unique
// public std declaration §18.2's fallback tier names (the bridge until
// #751). A user fn named like one of its helpers does not change what
// std.string's is_alnum calls.
fn is_digit(ch: u8) -> bool: ch > 1

fn main:
    // std.string's is_alnum on its own is_alpha/is_digit.
    assert(not is_alnum(33) and is_alnum(55) and is_alnum(97))
    // The user's is_digit at the user's call.
    assert(is_digit(5))
    print("ok")
