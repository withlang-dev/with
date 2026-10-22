//! expect-stdout: ok

// Deque[T] over the STC deque (docs/proposals/stdlib_sourcing_plan.md Phase
// 3): both ends push and pop, front/back and get observe,
// traversal, exactly-once drops of values left in a dropped deque.

use std.collections.deque.Deque

type Tag { id: i32, slot: *mut i32 }
impl Drop for Tag:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

fn ints():
    var d = Deque[i32].new()
    assert(d.is_empty() and d.front().is_none() and d.pop_front().is_none())
    d.push_back(2)
    d.push_back(3)
    d.push_front(1)
    assert(d.len() == 3)
    assert(*d.front().unwrap() == 1 and *d.back().unwrap() == 3)
    assert(*d.get(0) == 1 and *d.get(1) == 2 and *d.get(2) == 3)
    var cursor = d.iter()
    var seen: List[i32] = []
    while true:
        match cursor.next():
            Some(v) => seen.push(*v)
            None => break
    assert(seen == [1, 2, 3])
    assert(d.pop_front().unwrap() == 1 and d.pop_back().unwrap() == 3)
    assert(d.len() == 1 and *d.get(0) == 2)
    // Wraps around the ring buffer.
    for i in 0..100: d.push_back(i)
    for i in 0..50: assert(d.pop_front().is_some())
    assert(d.len() == 51)
    d.clear()
    assert(d.is_empty())

fn drops():
    var total: i32 = 0
    let slot = &raw mut total
    with 0 as scope:
        var d = Deque[Tag].new()
        for id in [5i32, 2, 8]: d.push_back(Tag { id: id, slot: slot })
        let first = d.pop_front().unwrap()
        drop(first)
        assert(total == 5)
    // The two left dropped with the deque: 2 + 8.
    assert(total == 15)

fn main:
    ints()
    drops()
    print("ok")
