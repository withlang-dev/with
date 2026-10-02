//! D22-NON-COMPLIANT
//! owner-stage: 6
//! required-verdict: compile-and-run under `--debug-alloc`
//! exact-type: `remove` yields owned `Vec[i64]`; retained values remain SlotMap-owned
//! expected-diagnostic: none
//! origin-set: the removed value has `{}`
//! drop-behavior: retained and removed Vec buffers plus SlotMap backing storage each drop exactly once; leak count=0
//! expect-debug-alloc: leak count=0

use std.collections.SlotMap
type Holder {
    slots: SlotMap[Vec[i64]],
}

fn main:
    var holder = Holder { slots: SlotMap.new() }

    let kept: Vec[i64] = Vec.new()
    kept.push(17)
    let _kept_handle = holder.slots.insert(move kept)

    let transferred: Vec[i64] = Vec.new()
    transferred.push(23)
    let transferred_handle = holder.slots.insert(move transferred)
    let owned = holder.slots.remove(transferred_handle).unwrap()
    assert(owned[0] == 23)
