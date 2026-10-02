//! expect-stdout: ok

// #669: a contextual enum-constructor argument to a storing method
// (slot.set(Some(x)) and friends) must type as the stored element's enum,
// not its payload — in generic and non-generic bodies alike.

use std.collections.SlotMap
use std.collections.HashMap
fn generic_slot_set[T](x: T) -> T:
    let values: Vec[Option[T]] = Vec.new()
    let empty: Option[T] = None
    values.push(empty)
    with values.slot(0) as mut slot:
        slot.set(Some(x))
    values.remove(0).unwrap()

fn main:
    // generic body, VecSlot.set
    assert(generic_slot_set(5) == 5)

    // non-generic VecSlot.set
    let vs: Vec[Option[i32]] = Vec.new()
    let e1: Option[i32] = None
    vs.push(e1)
    with vs.slot(0) as mut s1:
        s1.set(Some(11))
    assert(vs.remove(0).unwrap() == 11)

    // VecRange.set value argument
    let vr: Vec[Option[i32]] = Vec.new()
    let e2: Option[i32] = None
    let e3: Option[i32] = None
    vr.push(e2)
    vr.push(e3)
    with vr.range(0..2) as mut r:
        r.set(0, Some(12))
    assert(vr.remove(0).unwrap() == 12)

    // SlotMap.insert and SlotMapSlot.set
    var sm: SlotMap[Option[i32]] = SlotMap.new()
    let h = sm.insert(Some(13))
    assert(sm.get(h).unwrap() == Some(13))
    with sm.slot(h) as mut s2:
        s2.set(Some(14))
    assert(sm.get(h).unwrap() == Some(14))

    // HashMapEntry.set
    var m: HashMap[str, Option[i32]] = HashMap.new()
    let e4: Option[i32] = None
    m.insert("k", e4)
    with m.entry("k") as mut en:
        en.set(Some(15))
    assert(m.get("k").unwrap() == Some(15))

    print("ok")
