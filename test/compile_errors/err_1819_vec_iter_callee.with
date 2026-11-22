//! expect-check-fail: call to `m1` mutates global `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a `List[str]` global, viewed by
// the loop binding of a `for` over it, written by a callee
// while the view is live.
// A call writes every global its callee writes.

var G: List[str] = List.new()

fn m1():
    for i in 0..64: G.push(f"item{i}")

fn main:
    G.push("first" ++ "!")
    for r in G:
        m1()
        print(r)
        break
