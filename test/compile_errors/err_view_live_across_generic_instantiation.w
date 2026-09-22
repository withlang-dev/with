//! expect-check-fail: is a live view

// #1317: the first call of a generic function checks its concrete body in
// the middle of the caller's. That body check discarded the caller's live
// borrows instead of setting them aside, so the view `e` lost its borrow of
// `xs` at `show(e.key)` and the push that invalidates it compiled.

type KV { key: str, n: i32 }

fn show[T: Display](v: &T): print(v)

fn main:
    var xs: Vec[KV] = Vec.new()
    xs.push(KV { key: "a".clone(), n: 1 })
    let e = xs.get(0)
    show(e.key)
    xs.push(KV { key: "b".clone(), n: 2 })
    show(e.key)
