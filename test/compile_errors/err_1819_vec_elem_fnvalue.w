//! expect-check-fail: call to `apply` mutates global `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a named function handed to a callee as a value writes G
// while an element view of G is live: the callee may run it.
// A call writes every global its callee writes.

var G: List[str] = List.new()

fn grow():
    for i in 0..64: G.push(f"item{i}")

fn apply(f: fn() -> Unit): f()

fn main:
    G.push("first" ++ "!")
    let r = G[0]
    apply(grow)
    print(r)
