//! expect-check-fail: cannot assign to immutable variable

// #924 (§4.2.5): a method assignment is an assignment; its target is a
// mutable place, as `line = line.trim()` requires.
fn main:
    let line = " a "
    line .= trim()
    print(line)
