//! expect-stdout: 2 1 4
//! expect-stdout: 1 1
//! expect-stdout: 2 a c b
//! expect-stdout: 2 a c
//! expect-stdout: 2 4 6
//! expect-stdout: 2 2
//! expect-stdout: 2 2
//! expect-stdout: 2 1
//! expect-stdout: 2 5

// #1403 (§13.5, §13.6): a comprehension clause is §13.5's `for PATTERN in
// EXPR`; a refutable pattern skips the elements it does not match. Before
// the fix every element bound: `None` bound its absent payload and `(2, 3)`
// bound `b`.
use std.collections.HashMap
use std.collections.HashSet

enum E:
    A(i32)
    B

fn main:
    let opts: Vec[?i32] = [Some(1), None, Some(4)]
    let vs: Vec[i32] = [v for Some(v) in opts]
    print(f"{vs.len()} {vs[0]} {vs[1]}")
    let ts: Vec[(i32, i32)] = [(0, 1), (2, 3)]
    let bs: Vec[i32] = [b for (0, b) in ts]
    print(f"{bs.len()} {bs[0]}")

    // Views of a non-Copy element: nothing moves out of `ps`.
    var ps: Vec[(i32, str)] = Vec.new()
    ps.push((0, "a".clone()))
    ps.push((1, "b".clone()))
    ps.push((0, "c".clone()))
    let ss = [s.clone() for (0, s) in ps]
    print(f"{ss.len()} {ss[0]} {ss[1]} {ps[1].1}")

    // Consuming iteration: the skipped element is dropped, the rest move.
    let owned = [s for (0, s) in ps.into_iter()]
    print(f"{owned.len()} {owned[0]} {owned[1]}")

    // A filter reads what the pattern bound.
    let more: Vec[?i32] = [Some(1), None, Some(4), Some(6)]
    let big: Vec[i32] = [v for Some(v) in more if v > 1]
    print(f"{big.len()} {big[0]} {big[1]}")

    // Enum variants, a second clause, the map and set forms.
    let es: Vec[E] = [E.A(1), E.B, E.A(3)]
    let xs: Vec[i32] = [x for .A(x) in es]
    let pairs = [(v, b) for Some(v) in opts for (0, b) in ts]
    print(f"{xs.len()} {pairs.len()}")
    let m: HashMap[i32, i32] = [v: v * 2 for Some(v) in opts]
    let dups: Vec[?i32] = [Some(1), None, Some(1), Some(3)]
    let set: HashSet[i32] = [v for Some(v) in dups]
    print(f"{m.len()} {set.len()}")
    let rs: Vec[i32] = [x for 3 in 0..5 for x in 0..2]
    print(f"{rs.len()} {rs[1]}")
    print(f"{[a + b for (a, b) in ts].len()} {[a + b for (a, b) in ts][1]}")
