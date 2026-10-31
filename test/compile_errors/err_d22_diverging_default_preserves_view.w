//! expect-error: cannot mutate `map` while `view` is a live view into it
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 4
// required-verdict: check-fail at `map.clear()`
// exact-type: `view` is `&i32`; the diverging default does not anchor ownership
// expected-diagnostic: cannot mutate `map` while `view` is a live view into it
// origin-set: `view` has `{map}`
// drop-behavior: rejection precedes codegen; the map remains the sole owner

use std.collections.HashMap
fn observe(present: bool):
    var map: HashMap[i32, i32] = HashMap.new()
    if present:
        map.insert(1, 76)
    let view: &i32 = map.get(1) ?? return
    map.clear()
    assert(view == 76)

fn main: observe(true)
