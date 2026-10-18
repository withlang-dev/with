//! expect-error: cannot mutate `map` while `view` is a live view into it
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 4
// required-verdict: check-fail at `map.clear()`
// exact-type: ordinary `Some(value)` match projection binds `view: &i32`
// expected-diagnostic: cannot mutate `map` while `view` is a live view into it
// origin-set: the match projection preserves `{map}`
// drop-behavior: rejection precedes codegen; the map remains the sole owner

use std.collections.HashMap
fn main:
    var map: HashMap[i32, i32] = HashMap.new()
    map.insert(1, 101)
    let view = match map.get(1):
        Some(value) => value
        None => return
    map.clear()
    assert(view == 101)
