//! expect-debug-alloc: leak count=0
// #1302: a match on a place observes it. With str payloads live in the
// subject, matching a field, a local and a nested field twice in a row must
// neither free the payload (the owner's drop still runs once) nor leak it,
// and a `move` subject transfers the payload to the arm exactly once.
// The payloads are built at runtime: an all-literal `++` chain folds to one
// constant, allocates nothing, and the allocator then prints no report at all
// (the lane reads `leak count=0` from that report).
fn heap(a: str, b: str): a ++ b

enum Tok { LBrace | S(str) }
type P { cur: Option[Tok] = Some(.LBrace) }
type Outer { inner: P = P {} }

extend P:
    mut fn set(s: str): self.cur = Some(.S(s))
    fn is_s(): match self.cur { Some(.S(_)) => true, _ => false }
    mut fn probe() -> i32:
        var hits = 0
        if let Some(.S(_)) = self.cur: hits += 1
        let a = match self.cur:
            Some(.LBrace) => 0
            Some(.S(_)) => 1
            None => 2
        hits + a

fn main:
    var p = P {}
    p.set(heap("one", "two"))
    assert(p.is_s())
    assert(p.is_s())
    assert(p.probe() == 2)
    assert(p.probe() == 2)

    var x: Option[Tok] = Some(.S(heap("a", "b")))
    let l1 = match x { Some(.S(_)) => true, _ => false }
    let l2 = match x { Some(.S(_)) => true, _ => false }
    assert(l1 and l2)

    var o = Outer {}
    o.inner.set(heap("n", "1"))
    assert(o.inner.is_s())
    let n = match o.inner.cur { Some(.S(_)) => 1, _ => 0 }
    assert(n == 1)

    var m = P {}
    m.set(heap("m", "v"))
    let took = match move m.cur { Some(.S(s)) => s.len(), _ => 0 }
    assert(took == 2)
    m.cur = None
    let after = match m.cur { Some(_) => 1, None => 0 }
    assert(after == 0)
    print("ok")
