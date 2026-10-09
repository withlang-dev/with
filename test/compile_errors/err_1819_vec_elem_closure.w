//! expect-check-fail: call to `f` mutates global `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a `List[str]` global, viewed by
// an element view, written by a closure run in between
// while the view is live.
// A call writes every global its callee writes.

var G: List[str] = List.new()

fn main:
    G.push("first" ++ "!")
    let f: fn() -> Unit = () => { for i in 0..64: G.push(f"item{i}") }
    let r = G[0]
    f()
    print(r)
