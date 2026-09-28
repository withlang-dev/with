//! expect-check-fail: call to `gm` mutates global `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a `Vec[str]` global, viewed by
// a local `let r = &G`, written by a generic callee
// while the view is live.
// A call writes every global its callee writes.

var G: Vec[str] = Vec.new()

fn gm[T](x: T):
    for i in 0..64: G.push(f"item{i}")

fn main:
    G.push("first" ++ "!")
    let r = &G
    gm(1)
    print(r[0])
