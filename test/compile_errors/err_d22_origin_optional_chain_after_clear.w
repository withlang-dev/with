//! expect-error: cannot mutate `map` while `view` is a live view into it
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 4
// required-verdict: check-fail at `map.clear()`
// exact-type: optional field chaining yields `Option[&i32]`; `view` is `&i32`
// expected-diagnostic: cannot mutate `map` while `view` is a live view into it
// origin-set: construction, optional chaining, and unwrap preserve `{map}`
// drop-behavior: rejection precedes codegen; the map remains the sole owner

use std.collections.HashMap
type D22OptionalView = ephemeral { value: &i32 }

fn main:
    var map: HashMap[i32, i32] = HashMap.new()
    map.insert(1, 109)
    let carrier: Option[D22OptionalView] = Some(D22OptionalView { value: map.get(1).unwrap() })
    let view = carrier?.value.unwrap()
    map.clear()
    assert(view == 109)
