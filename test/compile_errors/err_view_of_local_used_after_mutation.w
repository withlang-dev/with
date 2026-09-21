//! expect-check-fail: is a live view

// #1249 / §21.1 rule 1: a shared borrow of a local is invalidated when the
// local is mutated; using the borrow afterwards is rejected. `let s = &v`
// registered no borrow for `s` (only element and map views did), so the
// stale read compiled.

fn main:
    var v: Vec[str] = Vec.new()
    v.push("a".clone())
    let s = &v
    v.push("b".clone())
    print(f"{s.len()}")
