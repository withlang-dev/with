//! expect-stdout: ok

// SortedVec[T] over the c-algorithms sorted array (docs/stdlib_sourcing_plan.md
// Phase 1): ordered insertion, observing views, transfers, binary search,
// and exactly-once drops of Drop-class values.

use std.builtins.print_i32
use std.collections.sorted_vec.SortedVec

type Tag { id: i32, slot: *mut i32 }
impl Ord for Tag:
    fn cmp(other: &Tag) -> i32:
        if self.id < other.id: -1 else if self.id > other.id: 1 else: 0
impl Drop for Tag:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

fn ints():
    var sorted = SortedVec[i32].new()
    for v in [5, 1, 4, 1, 3]: sorted.insert(v)
    assert(sorted.len() == 5)
    var expected = [1, 1, 3, 4, 5]
    for i in 0..5: assert(*sorted.get(i) == expected[i])
    assert(sorted.index_of(&3).unwrap() == 2)
    assert(sorted.index_of(&2).is_none())
    assert(sorted.contains(&5) and not sorted.contains(&9))
    assert(sorted.remove(0) == 1)
    assert(sorted.len() == 4 and *sorted.get(0) == 1)
    var cursor = sorted.iter()
    var sum = 0
    while let Some(v) = cursor.next():
        sum = sum + *v
    assert(sum == 13)
    sorted.clear()
    assert(sorted.is_empty())

fn drops(slot: *mut i32):
    var sorted = SortedVec[Tag].new()
    sorted.insert(Tag { id: 20, slot })
    sorted.insert(Tag { id: 10, slot })
    sorted.insert(Tag { id: 30, slot })
    assert(sorted.get(0).id == 10 and sorted.get(2).id == 30)
    let middle = sorted.remove(1)
    assert(middle.id == 20)
    drop(middle)

fn main:
    ints()
    var counter = 0
    drops(&raw mut counter)
    assert(counter == 60)
    print("ok")
