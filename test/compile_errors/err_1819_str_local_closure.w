//! expect-check-fail: call to `f` mutates global `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a `str` global, viewed by
// a local `let r = &G`, written by a closure run in between
// while the view is live.
// A call writes every global its callee writes.

var G: str = "ab" ++ "cd"

fn main:
    let f: fn() -> Unit = () => { G = "wx" ++ "yz" }
    let r = &G
    f()
    print(r)
