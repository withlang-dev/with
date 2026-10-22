//! expect-stdout: ok

// PriorityQueue[T] over the STC pqueue (docs/proposals/stdlib_sourcing_plan.md
// Phase 3): max and min ordering, peek observes, pop transfers, and
// exactly-once drops of Drop-class values left in a dropped queue.

use std.collections.priority_queue.PriorityQueue

type Tag { id: i32, slot: *mut i32 }
impl Ord for Tag:
    fn cmp(other: &Tag) -> i32:
        if self.id < other.id: -1 else if self.id > other.id: 1 else: 0
impl Drop for Tag:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

fn ints():
    var queue = PriorityQueue[i32].new()
    assert(queue.is_empty() and queue.peek().is_none() and queue.pop().is_none())
    for v in [3i32, 9, 1, 7, 9, 4]: queue.push(v)
    assert(queue.len() == 6)
    assert(*queue.peek().unwrap() == 9)
    var expected = [9, 9, 7, 4, 3, 1]
    for e in expected: assert(queue.pop().unwrap() == e)
    assert(queue.is_empty())
    var least = PriorityQueue[i32].new_min()
    for v in [3i32, 9, 1, 7]: least.push(v)
    assert(least.pop().unwrap() == 1 and least.pop().unwrap() == 3)

fn drops():
    var total: i32 = 0
    let slot = &raw mut total
    var popped: i32 = 0
    with 0 as scope:
        var queue = PriorityQueue[Tag].new()
        for id in [5i32, 2, 8, 1]: queue.push(Tag { id: id, slot: slot })
        let top = queue.pop().unwrap()
        popped = top.id
        drop(top)
        assert(total == 8)
    // The three left in the queue dropped with it: 5 + 2 + 1.
    assert(popped == 8 and total == 16)

fn main:
    ints()
    drops()
    print("ok")
