//! expect-check-fail: call to `f` mutates global `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a callee holds an element view of G across a run of its
// callable parameter; the closure bound to it calls a function that writes G.
// A call writes every global its callee writes.

var G: Vec[str] = Vec.new()

fn grow():
    for i in 0..64: G.push(f"item{i}")

fn apply(f: fn() -> Unit):
    let r = G[0]
    f()
    print(r)

fn main:
    G.push("first" ++ "!")
    let c: fn() -> Unit = () => grow()
    apply(c)
