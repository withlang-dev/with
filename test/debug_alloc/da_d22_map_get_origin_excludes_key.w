//! expect-debug-alloc: leak count=0
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 5
// required-verdict: compile-and-run under `--debug-alloc`
// exact-type: `view` is `&i32`
// expected-diagnostic: none when the lookup key is mutated
// origin-set: `view` has `{map}`, never `{key}`
// drop-behavior: the map remains sole owner; leak count=0

use std.collections.HashMap
fn main:
    var map: HashMap[i32, i32] = HashMap.new()
    map.insert(1, 87)
    var key = 1
    let view = map.get(key).unwrap()
    key = 2
    assert(view == 87)
