//! expect-stdout: ok

// D148's word shape for the B+tree: an integer key is the engine's own
// int64_t (an unsigned 64-bit key flips its sign bit, which keeps its
// order), no slot and no callback per comparison. Every integer width, both
// signs, the extremes, replacement, removal, traversal, clone, and
// exactly-once drops of the values.
use std.collections.BTreeMap
use std.collections.BTreeSet

type Tag { id: i32, slot: *mut i32 }
impl Drop for Tag:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

fn signed_keys():
    var m = BTreeMap[i64, str].new()
    m.insert(7, "seven")
    m.insert(-5, "minus five")
    m.insert(-9223372036854775808, "min")
    m.insert(9223372036854775807, "max")
    m.insert(0, "zero")
    var order = ""
    for (k, v) in m: order = order ++ f"{k}:{v};"
    assert(order == "-9223372036854775808:min;-5:minus five;0:zero;7:seven;9223372036854775807:max;")
    assert(*m.get(&-5).unwrap() == "minus five" and m.get(&6).is_none())
    m.insert(-5, "replaced")
    assert(m.len() == 5 and *m.get(&-5).unwrap() == "replaced")
    assert(m.remove(&0).unwrap() == "zero" and m.remove(&0).is_none() and m.len() == 4)
    let (fk, _) = m.first().unwrap()
    let (lk, _) = m.last().unwrap()
    assert(*fk == -9223372036854775808 and *lk == 9223372036854775807)
    let duplicate = m.clone()
    assert(duplicate.len() == 4 and *duplicate.get(&7).unwrap() == "seven")

fn unsigned_keys():
    var s = BTreeSet[u64].new()
    s.insert(18446744073709551615)
    s.insert(1)
    s.insert(9223372036854775808)
    s.insert(0)
    s.insert(9223372036854775807)
    var order = ""
    for v in s: order = order ++ f"{v},"
    assert(order == "0,1,9223372036854775807,9223372036854775808,18446744073709551615,")
    assert(s.contains(9223372036854775808) and not s.contains(2))
    assert(s.remove(18446744073709551615) and not s.remove(18446744073709551615) and s.len() == 4)
    var bytes = BTreeSet[u8].new()
    bytes.insert(255)
    bytes.insert(0)
    bytes.insert(128)
    assert(bytes.items() == [0, 128, 255])

fn narrow_keys():
    var m = BTreeMap[i8, i32].new()
    m.insert(127, 1)
    m.insert(-128, 2)
    m.insert(-1, 3)
    var keys = ""
    for k in m.keys(): keys = keys ++ f"{k},"
    assert(keys == "-128,-1,127,")
    var w = BTreeMap[u16, i32].new()
    w.insert(65535, 1)
    w.insert(2, 2)
    let (first, _) = w.first().unwrap()
    assert(*first == 2)
    var sizes = BTreeSet[isize].new()
    sizes.insert(-3)
    sizes.insert(3)
    assert(sizes.items() == [-3, 3])

fn value_drops():
    var total: i32 = 0
    let slot = &raw mut total
    if true:
        var m = BTreeMap[i32, Tag].new()
        m.insert(2, Tag { id: 20, slot: slot })
        m.insert(1, Tag { id: 10, slot: slot })
        m.insert(2, Tag { id: 200, slot: slot })
        assert(total == 20)
        let taken = m.remove(&1).unwrap()
        assert(taken.id == 10 and total == 20)
        drop(taken)
        assert(total == 30)
    assert(total == 230)

fn main:
    signed_keys()
    unsigned_keys()
    narrow_keys()
    value_drops()
    print("ok")
