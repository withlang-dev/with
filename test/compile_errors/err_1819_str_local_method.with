//! expect-check-fail: call to `W.go` mutates global `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a `str` global, viewed by
// a local `let r = &G`, written by a method of another type
// while the view is live.
// A call writes every global its callee writes.

var G: str = "ab" ++ "cd"

type W:
    x: i32

extend W:
    fn go():
        G = "wx" ++ "yz"

fn main:
    let r = &G
    W { x: 0 }.go()
    print(r)
