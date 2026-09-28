//! expect-check-fail: cannot mutate `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a struct global with a `str` field, viewed by
// a field view `let r = G.name`, written directly
// while the view is live.
// A call writes every global its callee writes.

type S:
    name: str
    n: i32

var G = S { name: "ab" ++ "cd", n: 1 }

fn main:
    let r = G.name
    G.name = "wx" ++ "yz"
    print(r)
