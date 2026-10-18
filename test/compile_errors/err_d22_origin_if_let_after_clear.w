//! expect-error: cannot mutate `map` while `view` is a live view into it
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 4
// required-verdict: check-fail at `map.clear()`
// exact-type: `if let Some(view)` binds `view: &i32`
// expected-diagnostic: cannot mutate `map` while `view` is a live view into it
// origin-set: the conditional pattern preserves `{map}`
// drop-behavior: rejection precedes codegen; the map remains the sole owner

use std.collections.HashMap
fn main:
    var map: HashMap[i32, i32] = HashMap.new()
    map.insert(1, 102)
    if let Some(view) = map.get(1):
        map.clear()
        assert(view == 102)
