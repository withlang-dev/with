//! expect-stdout: ok

// OrderedSet[T] over the STC sset (docs/proposals/stdlib_sourcing_plan.md
// Phase 3): ordered insertion, duplicates refused, get observes, remove
// transfers, in-order traversal, exactly-once drops.

use std.collections.ordered_set.OrderedSet

type Tag { id: i32, slot: *mut i32 }
impl Ord for Tag:
    fn cmp(other: &Tag) -> i32:
        if self.id < other.id: -1 else if self.id > other.id: 1 else: 0
impl Drop for Tag:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

fn ints():
    var set = OrderedSet[i32].new()
    assert(set.is_empty() and set.first().is_none() and set.last().is_none())
    for v in [5i32, 1, 9, 3, 7]: assert(set.insert(v))
    assert(not set.insert(3))
    assert(set.len() == 5)
    assert(set.contains(&7) and not set.contains(&8))
    assert(*set.get(&9).unwrap() == 9 and set.get(&2).is_none())
    assert(*set.first().unwrap() == 1 and *set.last().unwrap() == 9)
    var cursor = set.iter()
    var seen: List[i32] = []
    while true:
        match cursor.next():
            Some(v) => seen.push(*v)
            None => break
    assert(seen == [1, 3, 5, 7, 9])
    assert(set.remove(&5).unwrap() == 5 and set.remove(&5).is_none())
    assert(set.len() == 4 and not set.contains(&5))
    set.clear()
    assert(set.is_empty())

fn drops():
    var total: i32 = 0
    let slot = &raw mut total
    with 0 as scope:
        var set = OrderedSet[Tag].new()
        for id in [5i32, 2, 8, 1]: assert(set.insert(Tag { id: id, slot: slot }))
        // A duplicate is dropped on refusal: 8.
        assert(not set.insert(Tag { id: 8, slot: slot }))
        assert(total == 8)
        let taken = set.remove(&Tag { id: 2, slot: slot }).unwrap()
        // The probe dropped (2) and the taken value drops here (2).
        drop(taken)
        assert(total == 12)
    // The three left dropped with the set: 5 + 8 + 1.
    assert(total == 26)

fn main:
    ints()
    drops()
    print("ok")
