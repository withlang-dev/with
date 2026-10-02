//! D22-NON-COMPLIANT
//! owner-stage: 6
//! required-verdict: compile-and-run under `--debug-alloc`
//! exact-type: `SlotMapSlot.set` replaces one owned `Vec[i64]` with another
//! expected-diagnostic: none
//! origin-set: no lookup view escapes the mutation scope
//! drop-behavior: the replaced and replacement Vec buffers plus SlotMap storage each drop exactly once; leak count=0
//! expect-debug-alloc: leak count=0

use std.collections.SlotMap
fn main:
    var map: SlotMap[Vec[i64]] = SlotMap.new()
    let first: Vec[i64] = Vec.new()
    first.push(31)
    let handle = map.insert(move first)

    let replacement: Vec[i64] = Vec.new()
    replacement.push(37)
    with map.slot(handle) as mut slot:
        slot.set(move replacement)

    assert(map.get(handle).unwrap()[0] == 37)
