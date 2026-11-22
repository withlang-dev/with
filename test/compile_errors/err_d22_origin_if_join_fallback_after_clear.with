//! expect-error: cannot mutate `fallback` while `view` is a live view into it
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 4
// required-verdict: check-fail at `fallback.clear()`
// exact-type: the all-reference `if` result `view` is `&i32`
// expected-diagnostic: cannot mutate `fallback` while `view` is a live view into it
// origin-set: the `if` join gives `view` `{primary, fallback}`
// drop-behavior: rejection precedes codegen; both maps retain ownership

use std.collections.HashMap
fn main:
    var primary: HashMap[i32, i32] = HashMap.new()
    var fallback: HashMap[i32, i32] = HashMap.new()
    primary.insert(1, 105)
    fallback.insert(1, 106)
    let view: &i32 = if true: primary.get(1).unwrap() else: fallback.get(1).unwrap()
    fallback.clear()
    assert(view == 105)
