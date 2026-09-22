//! expect-check-fail: cannot infer return type: match arms have types i32 and Unit; add `-> i32` or `-> Unit`

// D43 / §9.1 (Eric, 2026-09-22): the braced arm-block spelling of
// err_d43_cannot_infer_match_block_arm.w. The arm block's assignment tail
// keeps the place's type; only a body's own tail is discarded.

var seen: i32
var hits: i32
fn f(p: bool):
    seen = 0
    match p:
        true => { hits += 1; seen = 1 }
        false => assert(p)

fn main: f(true)
