//! expect-check-fail: cannot infer return type: if arms have types i32 and Unit; add `-> i32` or `-> Unit`

// #1337 / D43 "both spellings, one rule" (Eric, 2026-09-22): an arm block
// ending in an assignment keeps the place's type however many statements
// precede it — the same answer as `if p: seen = 1` and `if p: { seen = 1 }`.

var seen: i32
fn f(p: bool):
    if p:
        let n = 1
        seen = n
    else:
        assert(not p)

fn main: f(true)
