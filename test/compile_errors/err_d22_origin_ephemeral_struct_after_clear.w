//! expect-error: cannot mutate `map` while `view` is a live view into it
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 4
// required-verdict: check-fail at `map.clear()`
// exact-type: `carrier` is ephemeral `D22View`; projected `view` is `&i32`
// expected-diagnostic: cannot mutate `map` while `view` is a live view into it
// origin-set: struct construction and field projection preserve `{map}`
// drop-behavior: rejection precedes codegen; the map remains the sole owner

use std.collections.HashMap
type D22View = ephemeral { value: &i32 }

fn main:
    var map: HashMap[i32, i32] = HashMap.new()
    map.insert(1, 107)
    let carrier = D22View { value: map.get(1).unwrap() }
    let view = carrier.value
    map.clear()
    assert(view == 107)
