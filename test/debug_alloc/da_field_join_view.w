//! expect-debug-alloc: leak count=0

// #1408, #1409: a join of field places (§3.8 join rule 3) borrows the places:
// no arm moves its field out, nothing is blanked, and every owner frees its
// field exactly once at its own scope exit. Before #1395 the arm moved the
// field into the join temporary and a reset blanked the owner's field — a
// second join over the same fields read "" (#1409); through a read `fn`
// receiver the moved field was freed by both the join and the caller.
use std.process

type S { s: str, v: Vec[str] }

impl S:
    fn pick(c: bool) -> i32:
        let x = if c: self.s else: self.s
        let y = match c:
            true => self.v
            false => self.v
        x.len() as i32 + y.len() as i32
    mut fn pick_mut(c: bool) -> i32:
        let x = if c: self.s else: self.s
        x.len() as i32

fn mk(t: &str) -> S:
    var v: Vec[str] = Vec.new()
    v.push(t.clone())
    S { s: t ++ "!", v }

fn main:
    let c = args().len() > 0
    let a = mk("a")
    var b = mk("bb")
    for _ in 0..3:
        let p = if c: a.s else: b.s
        let q = if c: { let _k = 1
            b.v } else: a.v
        assert(p.len() > 0 and q.len() == 1)
    assert(a.pick(c) == 3)
    assert(b.pick_mut(not c) == 3)
    assert(a.s == "a!" and b.s == "bb!")
    print("ok")
