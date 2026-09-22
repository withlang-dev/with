//! expect-stdout: mut-fn false false S(s1)
//! expect-stdout: fn false false S(s1)
//! expect-stdout: local true true S(a)
//! expect-stdout: nested 3 3 S(n)
//! expect-stdout: if-let 2 S(g)
//! expect-stdout: copy-payload 7 7 7
//! expect-stdout: let-else 4 4
//! expect-stdout: index true true S(e)
//! expect-stdout: move 2 drops=1
//! expect-stdout: reinit Some drops=1
//! expect-stdout: end drops=2

// #1302 (§9.7, D22/D27/D32): a match on a place OBSERVES it — a pattern is
// structural projection, not an owned-value demand. Matching `self.field`,
// `x.field`, a nested field, a local or an element with non-binding or
// Copy-binding patterns leaves the value where it is, so a second match still
// sees the variant and the payload is intact. Only an explicit `move` subject
// transfers, exactly once. Before the fix the subject was moved into a scratch
// temp and dropped, the field was reset to all-zero, and the next match
// decoded that sentinel as `Some(.LBrace)` (variant 0 of variant 0).

var drops: i32 = 0
enum Tok { LBrace | S(str) }
type Counted { id: i32 }
impl Drop for Counted:
    move fn drop(): drops = drops + 1
type P { n: i32 = 0, cur: Option[Tok] = Some(.LBrace), pair: (i32, str) = (7, "p") }
type Outer { inner: P = P {} }

fn show(t: &Option[Tok]) -> str:
    match t:
        Some(.LBrace) => "LBrace"
        Some(.S(s)) => f"S({s})"
        None => "None"

fn is_lbrace(t: &Option[Tok]) -> bool:
    match t { Some(.LBrace) => true, _ => false }

extend P:
    mut fn bump():
        self.n += 1
        self.cur = Some(.S(f"s{self.n}"))
    mut fn outer_mut() -> str:
        self.bump()
        let a = match self.cur:
            Some(.LBrace) => true
            _ => false
        let b = match self.cur:
            Some(.LBrace) => true
            _ => false
        f"mut-fn {a} {b} {show(&self.cur)}"
    fn outer_read() -> str:
        let a = match self.cur:
            Some(.LBrace) => true
            _ => false
        let b = match self.cur { Some(.LBrace) => true, _ => false }
        f"fn {a} {b} {show(&self.cur)}"
    fn first(): match self.pair { (k, _) => k }

fn main:
    var p = P {}
    print(p.outer_mut())
    print(p.outer_read())

    var x: Option[Tok] = Some(.S("a"))
    let l1 = match x { Some(.S(_)) => true, _ => false }
    let l2 = match x { Some(.S(_)) => true, _ => false }
    print(f"local {l1} {l2} {show(&x)}")

    var o = Outer {}
    o.inner.n = 3
    o.inner.cur = Some(.S("n"))
    let n1 = match o.inner.cur { Some(.S(_)) => o.inner.n, _ => 0 }
    let n2 = match o.inner.cur { Some(.S(_)) => o.inner.n, _ => 0 }
    print(f"nested {n1} {n2} {show(&o.inner.cur)}")

    var g = P { cur: Some(.S("g")) }
    var hits = 0
    if let Some(.S(_)) = g.cur: hits += 1
    if let Some(.S(_)) = g.cur: hits += 1
    print(f"if-let {hits} {show(&g.cur)}")

    // A Copy payload binding copies through an observed place.
    let c = P {}
    let c1 = match c.pair { (k, _) => k }
    let c2 = match c.pair { (k, _) => k }
    print(f"copy-payload {c1} {c2} {c.first()}")

    // let-else with a Copy binding observes too.
    var q = P { pair: (4, "q") }
    let (k1, _) = q.pair else: return
    let (k2, _) = q.pair else: return
    print(f"let-else {k1} {k2}")

    var v: Vec[Option[Tok]] = Vec.new()
    v.push(Some(.S("e")))
    let e1 = match v[0] { Some(.S(_)) => true, _ => false }
    let e2 = match v[0] { Some(.S(_)) => true, _ => false }
    print(f"index {e1} {e2} {show(&v[0])}")

    // An explicit `move` subject transfers exactly once: the payload drops in
    // the arm, the field is left empty, and the base's drop frees nothing more.
    var m: (Option[Counted], Option[Tok]) = (Some(Counted { id: 2 }), Some(.S("m")))
    let taken = match move m.0 { Some(cnt) => cnt.id, None => -1 }
    print(f"move {taken} drops={drops}")
    m.0 = Some(Counted { id: 9 })
    let again = match m.0 { Some(_) => "Some", None => "None" }
    print(f"reinit {again} drops={drops}")
    let _ = is_lbrace(&m.1)
    m = (None, None)
    print(f"end drops={drops}")
