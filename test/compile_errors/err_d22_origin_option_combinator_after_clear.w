//! expect-error: cannot mutate `map` while `view` is a live view into it
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 4
// required-verdict: check-fail at `map.clear()`
// exact-type: identity `map` keeps `Option[&i32]`; `view` is `&i32`
// expected-diagnostic: cannot mutate `map` while `view` is a live view into it
// origin-set: the non-owning combinator and unwrap preserve `{map}`
// drop-behavior: rejection precedes codegen; the map remains the sole owner

use std.collections.HashMap
fn main:
    var map: HashMap[i32, i32] = HashMap.new()
    map.insert(1, 110)
    let carried = map.get(1).map(value => value)
    let view = carried.unwrap()
    map.clear()
    assert(view == 110)
