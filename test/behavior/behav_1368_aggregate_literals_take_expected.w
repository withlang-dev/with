//! expect-stdout: 3.5 3 11 5 8 10 2 4

// #1368: a tuple or array literal written against an expected aggregate type
// is typed as that type (its elements take the expected widths), so every
// literal site still compiles: argument, Some payload, array parameter,
// assignment, struct field, Vec.push, return, and a literal mixing a typed
// local with a literal element.
fn f(t: (i64, f64)) -> f64: t.0 as f64 + t.1
fn g(o: Option[(i64, i64)]) -> i64: (o ?? (0, 0)).0
fn h(v: [2]i64) -> i64: v[0] + v[1]
type Q { t: (i64, i64) }
fn wide -> (i64, i64): (1, 2)
fn main:
    var w: (i64, i64) = (0, 0)
    w = (5, 6)
    let q = Q { t: (7, 8) }
    var v: Vec[(i64, i64)] = Vec.new()
    v.push((9, 10))
    let x: i64 = 3
    print(f"{f((1, 2.5))} {g(Some((3, 4)))} {h([5, 6])} {w.0} {q.t.1} {v[0].1} {wide().1} {f((x, 1.0))}")
