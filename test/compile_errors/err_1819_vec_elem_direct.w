//! expect-check-fail: cannot mutate `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a `Vec[str]` global, viewed by
// an element view, written directly
// while the view is live.
// A call writes every global its callee writes.

var G: Vec[str] = Vec.new()

fn main:
    G.push("first" ++ "!")
    let r = G[0]
    for i in 0..64: G.push(f"item{i}")
    print(r)
