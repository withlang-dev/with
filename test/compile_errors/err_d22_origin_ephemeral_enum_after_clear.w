//! expect-error: cannot mutate `map` while `view` is a live view into it
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 4
// required-verdict: check-fail at `map.clear()`
// exact-type: `D22Choice.Value` projects `view: &i32`
// expected-diagnostic: cannot mutate `map` while `view` is a live view into it
// origin-set: enum construction and pattern projection preserve `{map}`
// drop-behavior: rejection precedes codegen; the map remains the sole owner

use std.collections.HashMap
enum D22Choice ephemeral:
    Value(&i32)
    Empty

fn main:
    var map: HashMap[i32, i32] = HashMap.new()
    map.insert(1, 108)
    let carrier: D22Choice = D22Choice.Value(map.get(1).unwrap())
    let view = match carrier:
        D22Choice.Value(value) => value
        D22Choice.Empty => return
    map.clear()
    assert(view == 108)
