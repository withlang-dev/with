//! expect-stdout: [xy] [xy] [xy]
//! expect-stdout: a
//! expect-stdout: a
//! expect-stdout: b
//! expect-stdout: xy uv 2 in
//! expect-stdout: <xy> 2 xy
//! expect-stdout: 1 3
//! expect-stdout: xy uv
//! expect-stdout: [xy] [uv] [in] [tt]

// #1408, #1409 (§3.8 join rule 3; "a binding names what's there … uniform
// across field projections and collection element access"): an if/match
// whose arms are all places of non-Copy fields, with nothing owned to anchor
// it, joins as a view of those places — as `if c: v[0] else: v[1]` does.
// Before: the arms were owned demands, so the D32 funnel rejected them
// (after #1395); before #1395 the arm moved the field out and a second read
// saw "" (#1409).
use std.process

type S { s: str, n: i32 }
type Outer { inner: S, t: str }
type P { p: str, q: str }
type V { v: Vec[i32], w: Vec[i32] }

impl P:
    mut fn show(c: bool):
        let x = if c: self.p else: self.q
        print(x)
    fn peek(c: bool):
        let x = match c:
            true => self.p
            false => self.q
        print(x)

fn peek_len(v: &str) -> i32: v.len() as i32

fn pick(a: &S, b: &S, c: bool) -> &str: if c: a.s else: b.s

fn main:
    let x = S { s: "x" ++ "y", n: 1 }
    let y = S { s: "u" ++ "v", n: 2 }
    let c = args().len() > 0
    let p = if c: x.s else: y.s
    let q = if c: x.s else: y.s
    print(f"[{p}] [{q}] [{x.s}]")

    var s = P { p: "a" ++ "", q: "b" ++ "" }
    s.show(true)
    print(s.p)
    s.peek(false)

    let o = Outer { inner: S { s: "i" ++ "n", n: 3 }, t: "t" ++ "t" }
    let k = args().len() as i32
    let m = match k:
        0 => y.s
        1 => x.s
        _ => if k > 5: x.s else: y.s
    let blocked = if c: { let _n = 1
        x.s } else: y.s
    let nested = if c: o.inner.s else: o.t
    print(f"{m} {if not c: x.s else: y.s} {peek_len(if c: x.s else: y.s)} {nested}")
    let r = &y.s
    let mixed = if c: x.s else: r
    let typed: &str = if c: x.s else: y.s
    print(f"<{blocked}> {(if c: x.s else: y.s).len()} {if c: typed else: mixed}")

    var a: Vec[i32] = Vec.new()
    a.push(1)
    var b: Vec[i32] = Vec.new()
    b.push(2)
    b.push(3)
    let vs = V { v: a, w: b }
    let w = if c: vs.v else: vs.w
    print(f"{w.len()} {vs.v.len() + vs.w.len()}")
    print(f"{pick(&x, &y, c)} {pick(&x, &y, not c)}")
    print(f"[{x.s}] [{y.s}] [{o.inner.s}] [{o.t}]")
