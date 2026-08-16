//! skip-windows: issue #797: panic exits 1 not 134 on native Windows
//! expect-exit: 134
//! expect-stderr: SlotMap.get_disjoint requires distinct valid handles

use std.collections.SlotMap
fn main:
    var map = SlotMap[i32].new()
    let h = map.insert(1)
    let _slots = map.get_disjoint(h, h)
