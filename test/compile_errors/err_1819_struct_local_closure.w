//! expect-check-fail: call to `f` mutates global `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a struct global with a `str` field, viewed by
// a local `let r = &G`, written by a closure run in between
// while the view is live.
// A call writes every global its callee writes.

type S:
    name: str
    n: i32

var G = S { name: "ab" ++ "cd", n: 1 }

fn main:
    let f: fn() -> Unit = () => { G.name = "wx" ++ "yz" }
    let r = &G
    f()
    print(r.name)
