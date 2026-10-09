//! expect-stdout: ok

// #934: a comprehension iterates like a `for` (§13). The source List is
// borrowed, not moved — it stays usable afterwards for every element class —
// and Drop-class elements bind &T views that reach a `&T` parameter intact,
// over both the bare form and `.iter()`.
type Pair { a: i64, b: i64 }
fn peek_str(s: &str) -> i64: s.len()
fn peek_list(v: &List[i32]) -> i64: v.len() as i64
fn peek_pair(p: &Pair) -> i64: p.a + p.b
fn peek_i32(x: &i32) -> i64: *x as i64

fn main:
    let ints: List[i32] = [1, 2, 3]
    let doubled: List[i32] = [x * 2 for x in ints]
    if ints.len() != 3 or doubled.len() != 3 or doubled[2] != 6:
        print("FAIL copy-class source moved")
        return
    let via_fn: List[i64] = [peek_i32(x) for x in ints.iter()]
    if ints.len() != 3 or via_fn[0] != 1:
        print("FAIL i32 iter->fn")
        return
    var ss: List[str] = List.new()
    ss.push("hello")
    let a: List[i64] = [peek_str(s) for s in ss]
    let b: List[i64] = [peek_str(s) for s in ss.iter()]
    let c: List[i64] = [s.len() for s in ss]
    if ss.len() != 1:
        print("FAIL str source moved")
        return
    if a[0] != 5 or b[0] != 5 or c[0] != 5:
        print("FAIL str view")
        return
    var vs: List[List[i32]] = List.new()
    var inner: List[i32] = List.new()
    inner.push(1)
    inner.push(2)
    vs.push(move inner)
    let d: List[i64] = [peek_list(v) for v in vs]
    let e: List[i64] = [peek_list(v) for v in vs.iter()]
    if vs.len() != 1 or d[0] != 2 or e[0] != 2:
        print("FAIL vec view")
        return
    var ps: List[Pair] = List.new()
    ps.push(Pair { a: 3, b: 4 })
    let f: List[i64] = [peek_pair(p) for p in ps.iter()]
    if ps.len() != 1 or f[0] != 7:
        print("FAIL pair view")
        return
    print("ok")
