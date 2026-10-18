//! expect-error: cannot mutate `map` while `view` is a live view into it
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 4
// required-verdict: check-fail at `map.clear()`
// exact-type: `carry` is `Result[&i32, str]`; `view` is `&i32`
// expected-diagnostic: cannot mutate `map` while `view` is a live view into it
// origin-set: `Ok`, return forwarding, and `unwrap` preserve `{map}`
// drop-behavior: rejection precedes codegen; the map remains the sole owner

use std.collections.HashMap
fn carry(map: &HashMap[i32, i32]) -> Result[&i32, str]:
    Ok(map.get(1).unwrap())

fn main:
    var map: HashMap[i32, i32] = HashMap.new()
    map.insert(1, 74)
    let view = carry(&map).unwrap()
    map.clear()
    assert(view == 74)
