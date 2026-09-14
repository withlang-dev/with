//! expect-stdout: ok

// HashIndex[K, V] over the TommyDS hashdyn engine (docs/stdlib_sourcing_plan.md
// Phase 2): keyed insert/get/remove, replacement transfers the previous
// value, growth across several resizes, cursor, and exactly-once drops of
// Drop-class keys and values.

use std.collections.hash_index.HashIndex

type Tag { id: i32, slot: *mut i32 }
impl Drop for Tag:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

fn ints():
    var index = HashIndex[i32, i32].new()
    for i in 0..1000: assert(index.insert(i, i * 10).is_none())
    assert(index.len() == 1000)
    for i in 0..1000: assert(*index.get(&i).unwrap() == i * 10)
    assert(index.get(&1000).is_none())
    assert(index.insert(7, 700).unwrap() == 70)
    assert(index.len() == 1000 and *index.get(&7).unwrap() == 700)
    for i in 0..500: assert(index.remove(&i).unwrap() == (if i == 7: 700 else: i * 10))
    assert(index.remove(&0).is_none())
    assert(index.len() == 500 and not index.contains(&3) and index.contains(&999))
    var cursor = index.iter()
    var seen = 0
    var key_sum: i64 = 0
    while let Some(entry) = cursor.next():
        seen = seen + 1
        key_sum = key_sum + *entry.key()
        assert(*entry.value() == *entry.key() * 10)
    // The keys 500..999 remain: their sum is (500 + 999) * 500 / 2.
    assert(seen == 500 and key_sum == 374750)
    index.clear()
    assert(index.is_empty() and index.get(&999).is_none())
    index.insert(1, 1)
    assert(index.len() == 1)

fn strings():
    var index = HashIndex[str, i32].new()
    index.insert("alpha", 1)
    index.insert("beta", 2)
    assert(*index.get(&"beta").unwrap() == 2 and index.get(&"gamma").is_none())
    assert(index.remove(&"alpha").unwrap() == 1 and index.len() == 1)

unsafe fn drops(slot: *mut i32):
    var index = HashIndex[i32, Tag].new()
    for i in 1..9: assert(index.insert(i, Tag { id: i * 100, slot }).is_none())
    // Replacing transfers the old value out; dropping it here counts 100.
    let replaced = index.insert(1, Tag { id: 1000, slot }).unwrap()
    assert(replaced.id == 100)
    drop(replaced)
    assert(unsafe { *slot } == 100)
    // Removing transfers; the value counts when this scope drops it.
    let removed = index.remove(&2).unwrap()
    assert(removed.id == 200)
    drop(removed)
    assert(unsafe { *slot } == 300)
    // The index drops the rest exactly once: 1000 + 300..800.
    drop(index)
    assert(unsafe { *slot } == 300 + 1000 + 300 + 400 + 500 + 600 + 700 + 800)

fn main:
    ints()
    strings()
    var counter = 0
    unsafe { drops(&raw mut counter) }
    print("ok")
