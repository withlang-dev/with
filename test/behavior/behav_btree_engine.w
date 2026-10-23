//! expect-stdout: ok

// BTreeMap and BTreeSet over the M*LIB B+tree (docs/proposals/
// stdlib_sourcing_plan.md Phase 4, #937): key order, insert replaces, get
// observes, remove transfers, first/last, traversal and the consuming
// traversals, literals and comprehensions through the facade's `new()`,
// set algebra, `:?`, exactly-once drops of keys, values and elements.

use std.collections.BTreeMap
use std.collections.BTreeSet

type Tag { id: i32, slot: *mut i32 }
impl Drop for Tag:
    fn drop(move self: Self):
        // A clone the engine made for a separator (D151) has no slot and
        // counts nothing; it compares equal to its original.
        if self.slot != null:
            unsafe:
                *self.slot = *self.slot + self.id

fn ints():
    var map = BTreeMap[i32, str].new()
    assert(map.is_empty() and map.first().is_none())
    map.insert(5, "five")
    map.insert(1, "one")
    map.insert(9, "nine")
    map.insert(5, "FIVE")
    assert(map.len() == 3)
    assert(*map.get(&5).unwrap() == "FIVE" and map.get(&2).is_none())
    assert(map.contains(&1) and not map.contains(&4))
    let (fk, fv) = map.first().unwrap()
    assert(*fk == 1 and *fv == "one")
    let (lk, lv) = map.last().unwrap()
    assert(*lk == 9 and *lv == "nine")
    var order = ""
    for (k, v) in map: order = order ++ f"{k}={v};"
    assert(order == "1=one;5=FIVE;9=nine;")
    var keys = ""
    for k in map.keys(): keys = keys ++ f"{k},"
    assert(keys == "1,5,9,")
    var values = ""
    for v in map.values(): values = values ++ f"{v},"
    assert(values == "one,FIVE,nine,")
    assert(f"{map:?}" == "{1: \"one\", 5: \"FIVE\", 9: \"nine\"}")
    assert(map.remove(&5).unwrap() == "FIVE" and map.remove(&5).is_none())
    assert(map.len() == 2)
    map.clear()
    assert(map.is_empty() and map.get(&1).is_none())
    map.insert(2, "two")
    assert(map.len() == 1)

fn literals():
    let lit: BTreeMap[i32, str] = [3: "c", 1: "a", 2: "b"]
    var seen = ""
    for (k, v) in lit: seen = seen ++ f"{k}{v}"
    assert(seen == "1a2b3c")
    let set: BTreeSet[i32] = [3, 1, 2, 3]
    assert(set.len() == 3 and set.contains(&2))
    let keys: List[i32] = [4, 2, 3]
    let squares: BTreeMap[i32, i32] = [k: k * k for k in keys]
    var sq = ""
    for (k, v) in squares: sq = sq ++ f"{k}:{v} "
    assert(sq == "2:4 3:9 4:16 ")
    let raw: List[i32] = [8, 2, 6, 2]
    let evens: BTreeSet[i32] = [x for x in raw]
    assert(evens.items() == [2, 6, 8])
    var consumed = ""
    for (k, v) in lit.into_iter(): consumed = consumed ++ f"{k}{v}"
    assert(consumed == "1a2b3c")

fn sets():
    var a: BTreeSet[i32] = BTreeSet.new()
    for x in [5, 3, 9, 3]: a.insert(x)
    assert(a.len() == 3 and a.items() == [3, 5, 9])
    assert(a.remove(&5) and not a.remove(&5))
    var b: BTreeSet[i32] = [9, 11]
    assert(a.union(&b).items() == [3, 9, 11])
    assert(a.intersection(&b).items() == [9])
    assert(a.difference(&b).items() == [3])
    var walked = 0
    for x in a: walked = walked + *x
    assert(walked == 12)

unsafe fn scoped(slot: *mut i32):
    var map = BTreeMap[i32, Tag].new()
    for i in 1..9: map.insert(9 - i, Tag { id: 9 - i, slot: slot })
    map.insert(3, Tag { id: 30, slot: slot })
    assert(unsafe { *slot } == 3)
    let taken = map.remove(&4).unwrap()
    assert(taken.id == 4 and unsafe { *slot } == 3)
    drop(taken)
    assert(unsafe { *slot } == 7)
    var set = BTreeSet[Tag].new()
    set.insert(Tag { id: 100, slot: slot })
    set.insert(Tag { id: 200, slot: slot })
    let probe = Tag { id: 100, slot: slot }
    assert(set.remove(&probe))
    assert(unsafe { *slot } == 107)

fn drops():
    var total: i32 = 0
    unsafe { scoped(&raw mut total) }
    // 3 (replaced) + 4 (taken) + 30 + 1 + 2 + 5 + 6 + 7 + 8 (the map) +
    // 100 (removed) + 100 (the probe) + 200 (the set)
    assert(total == 466)

impl Clone for Tag:
    fn clone(self: &Self) -> Tag: Tag { id: self.id, slot: null }

impl Ord for Tag:
    fn cmp(self: &Self, other: &Tag) -> i32: self.id - other.id

fn main:
    ints()
    literals()
    sets()
    drops()
    print("ok")
