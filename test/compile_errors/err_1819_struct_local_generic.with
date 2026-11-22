//! expect-check-fail: call to `gm` mutates global `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a struct global with a `str` field, viewed by
// a local `let r = &G`, written by a generic callee
// while the view is live.
// A call writes every global its callee writes.

type S:
    name: str
    n: i32

var G = S { name: "ab" ++ "cd", n: 1 }

fn gm[T](x: T):
    G.name = "wx" ++ "yz"

fn main:
    let r = &G
    gm(1)
    print(r.name)
