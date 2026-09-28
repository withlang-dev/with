//! expect-check-fail: cannot mutate `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a closure literal handed to a callee writes G while
// an element view of G is live; the closure's own body is refused in place.
// A call writes every global its callee writes.

var G: Vec[str] = Vec.new()

fn apply(f: fn() -> Unit): f()

fn main:
    G.push("first" ++ "!")
    let r = G[0]
    apply(() => { for i in 0..64: G.push(f"item{i}") })
    print(r)
