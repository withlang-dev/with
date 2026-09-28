//! expect-check-fail: call to `m2` mutates global `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a struct global with a `str` field, viewed by
// a field view `let r = G.name`, written by a callee's callee
// while the view is live.
// A call writes every global its callee writes.

type S:
    name: str
    n: i32

var G = S { name: "ab" ++ "cd", n: 1 }

fn m1():
    G.name = "wx" ++ "yz"

fn m2(): m1()

fn main:
    let r = G.name
    m2()
    print(r)
