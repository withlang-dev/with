//! expect-error: cannot mutate `map` while `view` is a live view into it
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 6
// required-verdict: check-fail at `map.clear()`
// exact-type: `view` is `&i32`
// expected-diagnostic: cannot mutate `map` while `view` is a live view into it
// origin-set: `view` has `{map}`
// drop-behavior: rejection precedes codegen; the map remains the sole owner

use std.collections.BTreeMap
fn main:
    var map: BTreeMap[i32, i32] = BTreeMap.new()
    map.insert(1, 86)
    let view = map.get(1).unwrap()
    map.clear()
    assert(view == 86)
