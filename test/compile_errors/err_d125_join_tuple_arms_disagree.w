//! expect-check-fail: an aggregate's elements do not convert

// D125 (§4.2.1 rule 8, #1368): tuple arms whose element types differ do not
// join; neither arm becomes the other. `(str, i32)` beside `(str, isize)`
// once joined at whichever type was interned first, and the other arm
// reached MIR unconverted (invalid MIR before codegen).
fn owned(n: i32) -> (str, i32): ("x", n)

fn main:
    let b = true
    let (s, n) = if b: owned(2) else: ("n" ++ "o", 0)
    print(f"{s} {n}")
