//! expect-stdout: 2 2 2
//! expect-stdout: 3 ab
//! expect-stdout: 7

// #1402 (§9.3): a closure parameter annotated with a generic type keeps the
// whole annotation, `&List[i32]`, not its bracketed argument. By-reference
// and owned annotations, two annotated parameters, and a generic type as the
// second parameter.
use std.collections.HashMap

type W { n: i32 }

fn main:
    var xs: List[i32] = List.new()
    xs.push(1)
    xs.push(2)
    let f = (v: &List[i32]) => v.len()
    let g = (v: &List[i32], k: i32) => v.len() as i32 + k - k
    let h = (v: List[i32]) => v.len()
    print(f"{f(&xs)} {g(&xs, 5)} {h(xs.clone())}")
    let pair = (w: &W, m: &HashMap[str, i32]) => w.n + m.len() as i32
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("a", 1)
    m.insert("b", 2)
    let pick = (o: Option[str]) => o ?? "none"
    print(f"{pair(&W { n: 1 }, &m)} {pick(Some("ab"))}")
    let total = (a: &List[i32], b: &List[i64]) => a.len() + b.len() + 3
    var ys: List[i64] = List.new()
    ys.push(9)
    ys.push(9)
    print(f"{total(&xs, &ys)}")
