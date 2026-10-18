//! expect-debug-alloc: leak count=0
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 5
// required-verdict: compile-and-run under `--debug-alloc`
// exact-type: inferred `view` is `&i32`; `snapshot` and `removed` are owned `i32`
// expected-diagnostic: none
// origin-set: `view` has `{map}`; snapshot and removed values have `{}`
// drop-behavior: SlotMap storage is released once; leak count=0

use std.collections.SlotMap
fn main:
    var map: SlotMap[i32] = SlotMap.new()
    let handle = map.insert(88)
    let view = map.get(handle).unwrap()
    let snapshot: i32 = view
    let removed = map.remove(handle).unwrap()
    assert(snapshot == 88)
    assert(removed == 88)
