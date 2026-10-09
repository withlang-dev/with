//! expect-check-fail: call to `show` mutates global `G` while its argument is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a `List[str]` global, viewed by
// an argument that views a value in it (a `&str` parameter), written by a callee's callee
// while the view is live.
// A call writes every global its callee writes.

var G: List[str] = List.new()

fn m1():
    for i in 0..64: G.push(f"item{i}")

fn m2(): m1()

fn show(r: &str):
    m2()
    print(r)

fn main:
    G.push("first" ++ "!")
    show(G[0])
