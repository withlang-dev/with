//! expect-stdout: ok

// BinaryHeap[T] over the c-algorithms binary heap (docs/stdlib_sourcing_plan.md
// Phase 1): max and min ordering, peek observes, pop transfers, and
// exactly-once drops of Drop-class values left in a dropped heap.

use std.builtins.print_i32
use std.collections.binary_heap.BinaryHeap

type Tag { id: i32, slot: *mut i32 }
impl Ord for Tag:
    fn cmp(other: Tag) -> i32:
        if self.id < other.id: -1 else if self.id > other.id: 1 else: 0
impl Tag:
    fn lt(other: &Tag) -> bool: self.id < other.id
    fn gt(other: &Tag) -> bool: self.id > other.id
impl Drop for Tag:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

fn ints():
    var heap = BinaryHeap[i32].new()
    assert(heap.is_empty() and heap.peek().is_none() and heap.pop().is_none())
    for v in [3, 9, 1, 7, 9, 4]: heap.push(v)
    assert(heap.len() == 6)
    assert(*heap.peek().unwrap() == 9)
    var expected = [9, 9, 7, 4, 3, 1]
    for i in 0..6: assert(heap.pop().unwrap() == expected[i])
    assert(heap.pop().is_none())
    var low = BinaryHeap[i32].new_min()
    for v in [3, 9, 1, 7]: low.push(v)
    assert(*low.peek().unwrap() == 1)
    assert(low.pop().unwrap() == 1 and low.pop().unwrap() == 3)
    assert(low.len() == 2)

fn drops(slot: *mut i32):
    var heap = BinaryHeap[Tag].new()
    heap.push(Tag { id: 20, slot })
    heap.push(Tag { id: 10, slot })
    heap.push(Tag { id: 30, slot })
    assert(heap.peek().unwrap().id == 30)
    let top = heap.pop().unwrap()
    assert(top.id == 30)
    drop(top)

fn main:
    ints()
    var counter = 0
    drops(&raw mut counter)
    assert(counter == 60)
    print("ok")
