//! expect-error: cannot copy `OwnedBox` out of `ListSlot.get` because `OwnedBox` is not `Copy`
//! expect-error: cannot copy `OwnedBox` out of `ListRange.get` because `OwnedBox` is not `Copy`
//! expect-error: cannot copy `OwnedBox` out of `SlotMapSlot.get` because `OwnedBox` is not `Copy`
//! expect-error: cannot copy `OwnedBox` out of `HashMapEntry.or_insert` because `OwnedBox` is not `Copy`
//! expect-error: cannot copy `OwnedBox` out of `HashMapEntry.get` because `OwnedBox` is not `Copy`

// #1159 (D44 §2.3): slot, range, and entry `.get()` / `.or_insert()` return an
// owned `T` without removing the element from the container, so `T` must be `Copy`.

use std.collections.SlotMap
use std.collections.HashMap

resource type OwnedBox {
    id: i32,
}

impl Drop for OwnedBox:
    move fn drop():
        ()

fn main:
    var xs: List[OwnedBox] = List.new()
    xs.push(OwnedBox { id: 1 })
    with xs.slot(0) as mut s:
        let _ = s.get()

    with xs.range(0..1) as mut r:
        let _ = r.get(0)

    var sm: SlotMap[OwnedBox] = SlotMap.new()
    let h = sm.insert(OwnedBox { id: 3 })
    with sm.slot(h) as mut ss:
        let _ = ss.get()

    var m: HashMap[str, OwnedBox] = HashMap.new()
    with m.entry("k") as mut e:
        let _ = e.or_insert(OwnedBox { id: 4 })
        let _ = e.get()
