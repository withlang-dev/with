//! expect-error: cannot mutate `map` while `view` is a live view into it
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 4
// required-verdict: check-fail at `map.clear()`
// exact-type: inferred `find` return and `view` are `&i32`
// expected-diagnostic: cannot mutate `map` while `view` is a live view into it
// origin-set: the inferred return forwards `{map}`
// drop-behavior: rejection precedes codegen; the map remains the sole owner

use std.collections.HashMap
fn find(map: &HashMap[i32, i32]): map.get(1).unwrap()

fn main:
    var map: HashMap[i32, i32] = HashMap.new()
    map.insert(1, 82)
    let view: &i32 = find(&map)
    map.clear()
    assert(view == 82)
