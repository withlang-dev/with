//! expect-stdout: ok

// UnorderedSet[T] over the STC hset (D149: the unordered hash set beside
// the insertion-ordered HashSet): insert refuses duplicates, get observes,
// remove transfers, traversal visits every value once, exactly-once drops.

use std.collections.unordered_set.UnorderedSet

type Tag { id: i32, slot: *mut i32 }
impl Key for Tag:
    fn key(self: &Self): self.id
impl Drop for Tag:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

fn ints():
    var set = UnorderedSet[i32].new()
    assert(set.is_empty() and set.get(&1).is_none())
    for v in [5i32, 1, 9, 3, 7]: assert(set.insert(v))
    assert(not set.insert(3))
    assert(set.len() == 5)
    assert(set.contains(&7) and not set.contains(&8))
    assert(*set.get(&9).unwrap() == 9 and set.get(&2).is_none())
    var cursor = set.iter()
    var sum = 0
    var seen = 0
    while true:
        match cursor.next():
            Some(v) =>
                sum = sum + *v
                seen = seen + 1
            None => break
    assert(seen == 5 and sum == 25)
    assert(set.remove(&5).unwrap() == 5 and set.remove(&5).is_none())
    assert(set.len() == 4 and not set.contains(&5))
    set.clear()
    assert(set.is_empty())
    // Growth past the engine's first table.
    var big = UnorderedSet[i32].new()
    for i in 0..5000: assert(big.insert(i * 7919 % 5000))
    for i in 0..5000: assert(big.contains(&i))
    assert(big.len() == 5000)

fn strings():
    var names = UnorderedSet[str].new()
    assert(names.insert("alpha" ++ "1") and names.insert("beta") and not names.insert("beta"))
    assert(names.contains(&"alpha1") and names.remove(&"beta").unwrap() == "beta")
    assert(names.len() == 1)

fn drops():
    var total: i32 = 0
    let slot = &raw mut total
    with 0 as scope:
        var set = UnorderedSet[Tag].new()
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
    strings()
    drops()
    print("ok")

