//! expect-error: cannot mutate `map` while `left` is a live view into it
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 4
// required-verdict: check-fail at `map.clear()`
// exact-type: nested `left` and `right` bindings are `&i32`
// expected-diagnostic: cannot mutate `map` while `left` is a live view into it
// origin-set: both nested bindings have `{map}`
// drop-behavior: rejection precedes codegen; the map remains the sole owner

use std.collections.HashMap
fn main:
    var map: HashMap[i32, (i32, i32)] = HashMap.new()
    map.insert(1, (61, 62))
    let Some((left, right)) = map.get(1) else return
    map.clear()
    assert(left + right == 123)
