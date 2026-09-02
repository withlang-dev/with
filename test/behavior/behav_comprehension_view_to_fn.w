//! expect-stdout: ok

// #934: a comprehension iterates like a `for` (§13). The source Vec is
// borrowed, not moved — it stays usable afterwards for every element class —
// and Drop-class elements bind &T views that reach a `&T` parameter intact,
// over both the bare form and `.iter()`.
type Pair { a: i64, b: i64 }
fn peek_str(s: &str) -> i64: s.len()
fn peek_vec(v: &Vec[i32]) -> i64: v.len() as i64
fn peek_pair(p: &Pair) -> i64: p.a + p.b
fn peek_i32(x: &i32) -> i64: *x as i64

fn main:
    let ints: Vec[i32] = [1, 2, 3]
    let doubled: Vec[i32] = [x * 2 for x in ints]
    if ints.len() != 3 or doubled.len() != 3 or doubled.get(2) != 6:
        print("FAIL copy-class source moved")
        return
    let via_fn: Vec[i64] = [peek_i32(x) for x in ints.iter()]
    if ints.len() != 3 or via_fn.get(0) != 1:
        print("FAIL i32 iter->fn")
        return
    var ss: Vec[str] = Vec.new()
    ss.push("hello")
    let a: Vec[i64] = [peek_str(s) for s in ss]
    let b: Vec[i64] = [peek_str(s) for s in ss.iter()]
    let c: Vec[i64] = [s.len() for s in ss]
    if ss.len() != 1:
        print("FAIL str source moved")
        return
    if a.get(0) != 5 or b.get(0) != 5 or c.get(0) != 5:
        print("FAIL str view")
        return
    var vs: Vec[Vec[i32]] = Vec.new()
    var inner: Vec[i32] = Vec.new()
    inner.push(1)
    inner.push(2)
    vs.push(move inner)
    let d: Vec[i64] = [peek_vec(v) for v in vs]
    let e: Vec[i64] = [peek_vec(v) for v in vs.iter()]
    if vs.len() != 1 or d.get(0) != 2 or e.get(0) != 2:
        print("FAIL vec view")
        return
    var ps: Vec[Pair] = Vec.new()
    ps.push(Pair { a: 3, b: 4 })
    let f: Vec[i64] = [peek_pair(p) for p in ps.iter()]
    if ps.len() != 1 or f.get(0) != 7:
        print("FAIL pair view")
        return
    print("ok")
