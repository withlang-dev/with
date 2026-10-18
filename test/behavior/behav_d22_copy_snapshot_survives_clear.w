// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 5
// required-verdict: compile-and-run
// exact-type: inferred lookup payload is `&i32`; annotated `snapshot` is owned `i32`
// expected-diagnostic: none
// origin-set: the contextual Copy gives `snapshot` `{}`
// drop-behavior: the map remains sole storage owner and drops once

use std.collections.HashMap
fn main:
    var map: HashMap[i32, i32] = HashMap.new()
    map.insert(1, 46)
    let snapshot: i32 = map.get(1).unwrap()
    map.clear()
    assert(snapshot == 46)
