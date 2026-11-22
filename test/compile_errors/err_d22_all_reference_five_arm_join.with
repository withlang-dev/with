//! expect-error: cannot mutate `fallback` while `view` is a live view into it
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 4
// required-verdict: check-fail at `fallback.clear()`
// exact-type: with no owned anchor the five-arm match result `view` is `&i32`
// expected-diagnostic: cannot mutate `fallback` while `view` is a live view into it; identify all reaching reference arms
// origin-set: the match result has `{primary, fallback}`
// drop-behavior: rejection precedes codegen; both maps retain ownership

use std.collections.HashMap
fn main:
    var primary: HashMap[i32, i32] = HashMap.new()
    var fallback: HashMap[i32, i32] = HashMap.new()
    primary.insert(1, 112)
    fallback.insert(1, 113)
    let pick = 2
    let view: &i32 = match pick:
        0 => primary.get(1).unwrap()
        1 => fallback.get(1).unwrap()
        2 => primary.get(1).unwrap()
        3 => fallback.get(1).unwrap()
        _ => primary.get(1).unwrap()
    fallback.clear()
    assert(view == 112)
