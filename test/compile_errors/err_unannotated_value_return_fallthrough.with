//! expect-check-fail: missing return

// §4.10: "a function that demonstrably produces values elsewhere but falls
// off the end is reported as a missing return, not defaulted" (also §9.1).
// This shape was pinned as returning `0` from the fall-off (#1494); the
// spec rules the other way, so the pin is now the diagnostic.

fn maybe(flag: bool):
    if flag:
        return 7
    let _ = 0

fn main:
    assert(maybe(true) == 7)
    print("ok")
