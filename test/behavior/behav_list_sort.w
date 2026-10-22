//! expect-stdout: ok

// std.algorithms over the STC sort (docs/proposals/stdlib_sourcing_plan.md
// Phase 3, #940): `sort` for the word shapes (i64, u64, f64, in place
// through the engine's own instantiation) and for any other `T` (through
// slot references, every element moved exactly once), `sort_by`, the
// binary search and bounds, `reverse`; Drop-class elements drop exactly
// once.

use std.algorithms

type Tag { id: i32, slot: *mut i32 }
impl Ord for Tag:
    fn cmp(other: &Tag) -> i32:
        if self.id < other.id: -1 else if self.id > other.id: 1 else: 0
impl Drop for Tag:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

fn words():
    var xs: List[i64] = [5, -1, 9, 3, 9, 0]
    xs.sort()
    assert(xs == [-1, 0, 3, 5, 9, 9])
    var us: List[u64] = [5, 1, 9, 3]
    us.sort()
    assert(us == [1, 3, 5, 9])
    var fs: List[f64] = [2.5, -1.0, 0.5]
    fs.sort()
    assert(fs == [-1.0, 0.5, 2.5])
    var is: List[i32] = [4, 2, 8, 2, 6]
    is.sort()
    assert(is == [2, 2, 4, 6, 8])
    var ss: List[str] = ["pear", "apple", "fig"]
    ss.sort()
    assert(ss == ["apple", "fig", "pear"])
    var empty: List[i64] = []
    empty.sort()
    assert(empty.len() == 0)

fn searches():
    var xs: List[i32] = [1, 3, 3, 5, 9]
    assert(xs.binary_search(&3).is_some() and xs.binary_search(&4).is_none())
    assert(xs.binary_search(&9).unwrap() == 4)
    assert(xs.lower_bound(&3) == 1 and xs.upper_bound(&3) == 3)
    assert(xs.lower_bound(&0) == 0 and xs.lower_bound(&10) == 5)
    xs.reverse()
    assert(xs == [9, 5, 3, 3, 1])
    var by: List[i32] = [4, 2, 8, 6]
    by.sort_by((a, b) => if *a > *b: -1 else if *a < *b: 1 else: 0)
    assert(by == [8, 6, 4, 2])

fn drops():
    var total: i32 = 0
    let slot = &raw mut total
    with 0 as scope:
        var tags: List[Tag] = []
        for id in [5i32, 2, 8, 1]: tags.push(Tag { id: id, slot: slot })
        tags.sort()
        assert(tags[0].id == 1 and tags[1].id == 2 and tags[2].id == 5 and tags[3].id == 8)
        assert(total == 0)
    assert(total == 16)

fn main:
    words()
    searches()
    drops()
    print("ok")
