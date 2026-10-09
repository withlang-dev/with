//! expect-check-fail: call to `run` mutates global `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a callee forwards its callable parameter to another
// callee while it holds an element view of G; the closure a caller passes writes G.
// A call writes every global its callee writes.

var G: List[str] = List.new()

fn run(g: fn() -> Unit): g()

fn apply(f: fn() -> Unit):
    let r = G[0]
    run(f)
    print(r)

fn main:
    G.push("first" ++ "!")
    apply(() => { for i in 0..64: G.push(f"item{i}") })
