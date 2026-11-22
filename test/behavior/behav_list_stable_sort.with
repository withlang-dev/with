//! expect-stdout: ok

// std.algorithms: `stable_sort`/`stable_sort_by` keep equal elements in
// their input order (evaluated separately from the STC sort, whose
// quicksort gives no such contract: a merge sort over the same reference
// layout, every element moved exactly once); `shuffle` permutes through
// std.random (every element present once; a seeded run reproduces).
// Drop-class elements drop exactly once.

use std.algorithms
use std.random.seed

type Tag { id: i32, slot: *mut i32 }
impl Ord for Tag:
    fn cmp(other: &Tag) -> i32:
        if self.id < other.id: -1 else if self.id > other.id: 1 else: 0
impl Drop for Tag:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

fn stability():
    // Pairs ordered by the first field only: the second records input order.
    var pairs: List[(i32, i32)] = []
    for i in 0..64: pairs.push((i % 4, i))
    pairs.stable_sort_by((a, b) => if a.0 < b.0: -1 else if a.0 > b.0: 1 else: 0)
    for i in 1..64:
        assert(pairs[i - 1].0 <= pairs[i].0)
        if pairs[i - 1].0 == pairs[i].0: assert(pairs[i - 1].1 < pairs[i].1)
    var xs: List[i64] = [5, -1, 9, 3, 9, 0]
    xs.stable_sort()
    assert(xs == [-1, 0, 3, 5, 9, 9])
    var ss: List[str] = ["pear", "apple", "fig"]
    ss.stable_sort()
    assert(ss == ["apple", "fig", "pear"])
    var empty: List[i64] = []
    empty.stable_sort()
    assert(empty.len() == 0)
    var one: List[i32] = [7]
    one.stable_sort()
    assert(one == [7])

fn shuffles():
    var xs: List[i32] = []
    for i in 0..100: xs.push(i)
    seed(42)
    xs.shuffle()
    var sorted = xs.clone()
    sorted.sort()
    for i in 0..100: assert(sorted[i] == i)
    var moved = 0
    for i in 0..100:
        if xs[i] != i: moved = moved + 1
    assert(moved > 50)
    var again: List[i32] = []
    for i in 0..100: again.push(i)
    seed(42)
    again.shuffle()
    assert(again == xs)
    var words: List[str] = ["a", "b", "c", "d", "e", "f", "g", "h"]
    words.shuffle()
    var back = words.clone()
    back.sort()
    assert(back == ["a", "b", "c", "d", "e", "f", "g", "h"])
    var empty: List[i32] = []
    empty.shuffle()
    assert(empty.len() == 0)

fn drops():
    var total: i32 = 0
    let slot = &raw mut total
    with 0 as scope:
        var tags: List[Tag] = []
        for id in [5i32, 2, 8, 1, 2]: tags.push(Tag { id: id, slot: slot })
        tags.stable_sort()
        assert(tags[0].id == 1 and tags[1].id == 2 and tags[2].id == 2 and tags[3].id == 5 and tags[4].id == 8)
        tags.shuffle()
        assert(total == 0)
    assert(total == 18)

fn main:
    stability()
    shuffles()
    drops()
    print("ok")
