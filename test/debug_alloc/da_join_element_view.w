//! expect-debug-alloc: leak count=0
// #1406: element views carried through joins, tuples, Option and `??` are
// used before their origin reallocates; independent values cross the
// mutation as clones. Every str is freed exactly once and nothing leaks.

fn mkv() -> Vec[str]:
    var v: Vec[str] = Vec.new()
    v.push("alpha".clone())
    v.push("beta".clone())
    v

fn joins(c: bool) -> i64:
    var v = mkv()
    let x = if c: v[0] else: v[1]
    let t = (v[0], v[1])
    let o = if c: Some(v[1]) else: None
    let y = o ?? v[0]
    var n = x.len() + (t.0).len() + (t.1).len() + y.len()
    let kept = if c: v[0].clone() else: v[1].clone()
    for i in 0..64:
        v.push("gamma".clone())
    n = n + kept.len() + v.len()
    n

fn main:
    print(joins(true))
    print(joins(false))
