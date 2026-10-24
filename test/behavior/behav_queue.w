//! expect-stdout: ok

// Queue[T] over the STC queue (docs/proposals/stdlib_sourcing_plan.md Phase
// 3): push at the back, pop at the front, front/back observe, traversal
// front to back across the ring's wrap, the word shape for integer
// scalars, exactly-once drops of values left in a dropped queue.

use std.collections.queue.Queue

type Tag { id: i32, slot: *mut i32 }
impl Drop for Tag:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

fn strings():
    var q = Queue[str].new()
    assert(q.is_empty() and q.front().is_none() and q.pop().is_none())
    q.push("a")
    q.push("b")
    q.push("c")
    assert(q.len() == 3 and *q.front().unwrap() == "a" and *q.back().unwrap() == "c")
    var cursor = q.iter()
    var seen: List[str] = []
    while let Some(v) = cursor.next(): seen.push(*v)
    assert(seen == ["a", "b", "c"])
    assert(q.pop().unwrap() == "a" and q.pop().unwrap() == "b")
    assert(q.len() == 1 and *q.front().unwrap() == "c")
    // Wraps around the ring buffer.
    for i in 0..100: q.push(f"{i}")
    for i in 0..50: assert(q.pop().is_some())
    assert(q.len() == 51 and *q.front().unwrap() == "49" and *q.back().unwrap() == "99")
    var count = 0
    var again = q.iter()
    while let Some(v) = again.next(): count = count + 1
    assert(count == 51)
    q.clear()
    assert(q.is_empty())

// The word shape: integer scalars live inline in the engine's ring.
fn words():
    var q = Queue[i64].new()
    for i in 0..1000: q.push(i as i64 * 3)
    for i in 0..500: assert(q.pop().unwrap() == i as i64 * 3)
    assert(q.len() == 500 and *q.front().unwrap() == 1500 and *q.back().unwrap() == 2997)
    var sum: i64 = 0
    var cursor = q.iter()
    while let Some(v) = cursor.next(): sum = sum + *v
    assert(sum == 500 * (1500 + 2997) / 2)
    var bytes = Queue[u8].new()
    bytes.push(255)
    bytes.push(1)
    assert(bytes.pop().unwrap() == 255 and bytes.pop().unwrap() == 1 and bytes.is_empty())
    var negatives = Queue[i32].new()
    negatives.push(-7)
    assert(*negatives.front().unwrap() == -7 and negatives.pop().unwrap() == -7)

fn drops():
    var total: i32 = 0
    let slot = &raw mut total
    with 0 as scope:
        var q = Queue[Tag].new()
        for id in [5i32, 2, 8]: q.push(Tag { id: id, slot: slot })
        let first = q.pop().unwrap()
        drop(first)
        assert(total == 5)
    // The two left dropped with the queue: 2 + 8.
    assert(total == 15)

fn main:
    strings()
    words()
    drops()
    print("ok")
