//! expect-check-fail: call to `f` mutates global `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a struct global with a `List` field, viewed by
// a field view `let r = G.name`, written by a closure run in between
// while the view is live.
// A call writes every global its callee writes.

type S:
    name: List[i32]    // a str field would take the value (#3026, D111); the view rule needs a List
    n: i32

var G = S { name: [1, 2], n: 1 }

fn main:
    let f: fn() -> Unit = () => { G.name = [9, 9] }
    let r = G.name
    f()
    print(r.len())
