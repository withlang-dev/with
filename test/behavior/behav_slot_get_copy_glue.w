//! expect-stdout: ok

// #1159 (D44 §2.3, D111): slot/range/entry extraction methods (`ListSlot.get`,
// `ListRange.get`, `SlotMapSlot.get`, `HashMapEntry.get`, `HashMapEntry.or_insert`)
// return an owned `T: Copy` by running copy glue (`mir_emit_copy_glue_ptr`)
// rather than raw byte-copying refcounted `str` fields, and `ListRange.set` /
// `HashMapEntry.set` / `HashMapEntry.or_insert` properly retain/release keys
// and overwritten elements.

use std.collections.SlotMap
use std.collections.HashMap

type Courier {
    name: str,
    n: i32,
}

fn heap_str(tag: &str, k: i32) -> str:
    f"heap-{tag}-{k}-payload"

fn main:
    // 1. ListSlot.get and ListSlot.set with heap str and Courier (Copy struct with str field)
    var xs: List[Courier] = List.new()
    xs.push(Courier { name: heap_str("slot", 1), n: 10 })
    with xs.slot(0) as mut s:
        let c1 = s.get()
        assert(c1.name == "heap-slot-1-payload" and c1.n == 10)
        s.set(Courier { name: heap_str("slot", 2), n: 20 })
        let c2 = s.get()
        assert(c2.name == "heap-slot-2-payload" and c2.n == 20)
    assert(xs[0].name == "heap-slot-2-payload" and xs[0].n == 20)

    // 2. ListRange.get and ListRange.set with Courier
    var rs: List[Courier] = List.new()
    rs.push(Courier { name: heap_str("range", 1), n: 1 })
    rs.push(Courier { name: heap_str("range", 2), n: 2 })
    with rs.range(0..2) as mut r:
        let g0 = r.get(0)
        let g1 = r.get(1)
        assert(g0.name == "heap-range-1-payload" and g1.name == "heap-range-2-payload")
        r.set(0, Courier { name: heap_str("range", 3), n: 3 })
        let g2 = r.get(0)
        assert(g2.name == "heap-range-3-payload" and g2.n == 3)
    assert(rs[0].name == "heap-range-3-payload" and rs[1].name == "heap-range-2-payload")

    // 3. SlotMapSlot.get and SlotMapSlot.set with Courier
    var sm: SlotMap[Courier] = SlotMap.new()
    let h = sm.insert(Courier { name: heap_str("sm", 1), n: 100 })
    with sm.slot(h) as mut ss:
        let sc1 = ss.get()
        assert(sc1.name == "heap-sm-1-payload" and sc1.n == 100)
        ss.set(Courier { name: heap_str("sm", 2), n: 200 })
        let sc2 = ss.get()
        assert(sc2.name == "heap-sm-2-payload" and sc2.n == 200)
    assert(sm.get(h).unwrap().name == "heap-sm-2-payload")

    // 4. HashMapEntry.or_insert, get, set with heap str key and Courier value
    var m: HashMap[str, Courier] = HashMap.new()
    let k1 = heap_str("key", 1)
    with m.entry(k1) as mut e1:
        let v1 = e1.or_insert(Courier { name: heap_str("val", 1), n: 7 })
        assert(v1.name == "heap-val-1-payload" and v1.n == 7)
        let v1b = e1.get()
        assert(v1b.name == "heap-val-1-payload" and v1b.n == 7)
    // Existing entry: or_insert must drop the unused default value and copy the stored value
    with m.entry(k1) as mut e2:
        let v2 = e2.or_insert(Courier { name: heap_str("unused", 99), n: 99 })
        assert(v2.name == "heap-val-1-payload" and v2.n == 7)
        e2.set(Courier { name: heap_str("val", 2), n: 8 })
        let v3 = e2.get()
        assert(v3.name == "heap-val-2-payload" and v3.n == 8)
    let k2 = heap_str("key", 2)
    with m.entry(k2) as mut e3:
        e3.set(Courier { name: heap_str("val", 3), n: 9 })
        let v4 = e3.get()
        assert(v4.name == "heap-val-3-payload" and v4.n == 9)
    assert(m.get(k1).unwrap().name == "heap-val-2-payload")
    assert(m.get(k2).unwrap().name == "heap-val-3-payload")

    print("ok")
