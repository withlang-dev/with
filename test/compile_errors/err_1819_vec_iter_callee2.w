//! expect-check-fail: call to `m2` mutates global `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a `Vec[str]` global, viewed by
// the loop binding of a `for` over it, written by a callee's callee
// while the view is live.
// A call writes every global its callee writes.

var G: Vec[str] = Vec.new()

fn m1():
    for i in 0..64: G.push(f"item{i}")

fn m2(): m1()

fn main:
    G.push("first" ++ "!")
    for r in G:
        m2()
        print(r)
        break
