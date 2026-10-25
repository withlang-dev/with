//! expect-stdout: ok

// PriorityQueue[T] over the STC pqueue (stdlib_sourcing_plan.md
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
    assert(*least.peek().unwrap() == 1)
    assert(least.pop().unwrap() == 1 and least.pop().unwrap() == 3)

// The word shape (D148): a max-queue of an integer scalar keeps its values
// in the engine's own heap; negatives, narrow widths and the extremes keep
// their order, and an unsigned 64-bit key rides the slot shape.
fn words():
    var negatives = PriorityQueue[i64].new()
    for v in [-3i64, 9223372036854775807i64, -9223372036854775807i64 - 1, 0, 5]: negatives.push(v)
    assert(*negatives.peek().unwrap() == 9223372036854775807)
    assert(negatives.pop().unwrap() == 9223372036854775807 and negatives.pop().unwrap() == 5)
    assert(negatives.pop().unwrap() == 0 and negatives.pop().unwrap() == -3)
    assert(negatives.pop().unwrap() == -9223372036854775807i64 - 1 and negatives.is_empty())
    var bytes = PriorityQueue[u8].new()
    for v in [1u8, 255, 128]: bytes.push(v)
    assert(bytes.pop().unwrap() == 255 and bytes.pop().unwrap() == 128 and bytes.pop().unwrap() == 1)
    var shorts = PriorityQueue[i16].new()
    for v in [-32768i16, 32767, -1]: shorts.push(v)
    assert(*shorts.peek().unwrap() == 32767 and shorts.pop().unwrap() == 32767 and shorts.pop().unwrap() == -1)
    var big = PriorityQueue[u64].new()
    for v in [7u64, 18446744073709551615u64, 9223372036854775808u64]: big.push(v)
    assert(big.pop().unwrap() == 18446744073709551615u64 and big.pop().unwrap() == 9223372036854775808u64 and big.pop().unwrap() == 7)
    var many = PriorityQueue[i32].new()
    for i in 0..1000: many.push((i * 7919) % 1000)
    var prev = 1000
    for i in 0..1000:
        let v = many.pop().unwrap()
        assert(v <= prev)
        prev = v

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
    words()
    drops()
    print("ok")
