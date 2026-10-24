//! expect-stdout: ok

// LinkedList[T] over the STC list (docs/proposals/stdlib_sourcing_plan.md
// Phase 3): push at both ends, pop at the front, front/back observe,
// traversal, reverse and sort, the word shape for integer scalars (the
// unsigned 64-bit order kept through the engine's signed sort),
// exactly-once drops of values left in a dropped list.

use std.collections.linked_list.LinkedList

type Tag { id: i32, slot: *mut i32 }
impl Ord for Tag:
    fn cmp(other: &Tag) -> i32:
        if self.id < other.id: -1 else if self.id > other.id: 1 else: 0
impl Drop for Tag:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

fn collect(l: &LinkedList[str]) -> List[str]:
    var seen: List[str] = []
    var cursor = l.iter()
    while let Some(v) = cursor.next(): seen.push(*v)
    seen

fn strings():
    var l = LinkedList[str].new()
    assert(l.is_empty() and l.front().is_none() and l.pop_front().is_none())
    l.push_back("b")
    l.push_back("c")
    l.push_front("a")
    assert(l.len() == 3 and *l.front().unwrap() == "a" and *l.back().unwrap() == "c")
    assert(collect(&l) == ["a", "b", "c"])
    l.reverse()
    assert(collect(&l) == ["c", "b", "a"])
    l.sort()
    assert(collect(&l) == ["a", "b", "c"])
    assert(l.pop_front().unwrap() == "a")
    assert(l.len() == 2 and *l.front().unwrap() == "b")
    l.push_front("z")
    l.push_back("m")
    l.sort()
    assert(collect(&l) == ["b", "c", "m", "z"])
    l.clear()
    assert(l.is_empty() and l.back().is_none())

// The word shape: integer scalars live inline in the engine's nodes.
fn words():
    var l = LinkedList[i64].new()
    for i in 0..1000: l.push_back(i as i64 * 3)
    for i in 0..500: assert(l.pop_front().unwrap() == i as i64 * 3)
    assert(l.len() == 500 and *l.front().unwrap() == 1500 and *l.back().unwrap() == 2997)
    l.push_front(-5)
    l.sort()
    assert(*l.front().unwrap() == -5)
    var prev: i64 = -6
    var cursor = l.iter()
    while let Some(v) = cursor.next():
        assert(*v > prev)
        prev = *v
    var bytes = LinkedList[u8].new()
    bytes.push_back(255)
    bytes.push_front(1)
    assert(bytes.pop_front().unwrap() == 1 and bytes.pop_front().unwrap() == 255 and bytes.is_empty())
    // The unsigned 64-bit order through the signed engine sort.
    var big = LinkedList[u64].new()
    big.push_back(18446744073709551615)
    big.push_back(7)
    big.push_back(9223372036854775808)
    big.sort()
    assert(big.pop_front().unwrap() == 7)
    assert(big.pop_front().unwrap() == 9223372036854775808)
    assert(big.pop_front().unwrap() == 18446744073709551615)

fn drops():
    var total: i32 = 0
    let slot = &raw mut total
    with 0 as scope:
        var l = LinkedList[Tag].new()
        for id in [5i32, 2, 8]: l.push_back(Tag { id: id, slot: slot })
        l.sort()
        let first = l.pop_front().unwrap()
        assert(first.id == 2)
        drop(first)
        assert(total == 2)
    // The two left dropped with the list: 5 + 8.
    assert(total == 15)

fn main:
    strings()
    words()
    drops()
    print("ok")
