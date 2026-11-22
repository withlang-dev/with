//! expect-stdout: 1 5
//! expect-stdout: 7 3 9
// #1531 (§3.8, D27): a Copy field binds a view like a Copy element; the
// annotation `let x: i32 = s.n` is the owned copy, independent of later
// writes. A view read before the write, and a join of two Copy fields (a
// `&i32` view join, as `if c: v[0] else: v[1]` is), keep working.

type S { n: i32, m: i32 }

fn main:
    var s = S { n: 1, m: 3 }
    let before: i32 = s.n
    s.n = 5
    print(f"{before} {s.n}")
    let seen = s.m
    let sum = seen + 4
    let c = true
    let j = if c: s.n else: s.m
    let k = if not c: s.n else: s.m
    print(f"{sum} {k} {j + 4}")
