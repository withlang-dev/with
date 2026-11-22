//! expect-exit: 134
//! expect-stderr: SlotMap.get_disjoint requires distinct valid handles

fn main:
    var map = SlotMap[i32].new()
    let h = map.insert(1)
    let _slots = map.get_disjoint(h, h)
