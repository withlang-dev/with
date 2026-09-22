//! expect-check-fail: cannot infer return type: match arms have types i32 and Unit; add `-> i32` or `-> Unit`

// D43 / §9.1 (Eric, 2026-09-22): only a function's or closure's own body tail
// discards an assignment. An arm block's tail keeps the place's type, so the
// block spelling of err_d43_cannot_infer_match.w gets the same answer.
// (#1319 discarded every block's assignment tail and inferred Unit here.)

var seen: i32
var hits: i32
fn f(p: bool):
    seen = 0
    match p:
        true =>
            hits += 1
            seen = 1
        false => assert(p)

fn main: f(true)
