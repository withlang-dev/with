//! expect-stdout: take_same_buf true
//! expect-stdout: ys 10 99 30 40
//! expect-stdout: view alpha xs 3 ys 4 delta
//! expect-stdout: hoist 3 53 1 100 149
//! expect-stdout: inloop 1 2 3 4 50
//! expect-stdout: map_set 2 12 1 9 1 11

// D120 stage 4 (§2.3): static uniqueness proof, loop-invariant make-unique
// hoisting, and widened last-use take handoff after dead views.

use std.collections.HashMap
use std.collections.HashSet

fn pass_through_after_reads(xs: List[i64]) -> List[i64]:
    let n = xs.len()
    let first = xs[0]
    assert(n == 4 and first == 10)
    xs

fn main:
    var xs: List[i64] = List.with_capacity(8)
    xs.push(10)
    xs.push(20)
    xs.push(30)
    xs.push(40)
    let orig_ptr = xs.as_ptr() as usize
    let head = xs[0]
    assert(head == 10)
    var ys = pass_through_after_reads(xs)
    ys[1] = 99
    let same_buf = (ys.as_ptr() as usize) == orig_ptr
    print(f"take_same_buf {same_buf}")
    print(f"ys {ys[0]} {ys[1]} {ys[2]} {ys[3]}")

    var strs = ["alpha", "beta", "gamma"]
    let view = &strs[0]
    var strs2 = strs
    strs2.push("delta")
    print(f"view {*view} xs {strs.len()} ys {strs2.len()} {strs2[3]}")

    let base = [1, 2, 3]
    var work = base
    for i in 0..50:
        work.push(i + 100)
    print(f"hoist {base.len()} {work.len()} {work[0]} {work[3]} {work[52]}")

    var cur = [10]
    var snapshots: List[List[i32]] = List.new()
    for i in 0..4:
        snapshots.push(cur)
        cur.push((i + 2) * 10)
    print(f"inloop {snapshots[0].len()} {snapshots[1].len()} {snapshots[2].len()} {snapshots[3].len()} {cur[4]}")

    var m1: HashMap[str, i32] = HashMap.new()
    m1.insert("a", 1)
    m1.insert("b", 2)
    var m2 = m1
    for i in 0..10:
        m2.insert(f"k{i}", i)
    var s1: HashSet[i32] = HashSet.new()
    s1.insert(1)
    var s2 = s1
    for i in 10..20:
        s2.insert(i)
    print(f"map_set {m1.len()} {m2.len()} {m1.get(\"a\") ?? 0} {m2.get(\"k9\") ?? 0} {s1.len()} {s2.len()}")
