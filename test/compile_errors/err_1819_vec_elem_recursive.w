//! expect-check-fail: call to `walk` mutates global `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a recursive callee writes G at the bottom of its recursion.
// A call writes every global its callee writes.

var G: Vec[str] = Vec.new()

fn walk(n: i32):
    if n == 0:
        for i in 0..64: G.push(f"item{i}")
    else:
        walk(n - 1)

fn main:
    G.push("first" ++ "!")
    let r = G[0]
    walk(3)
    print(r)
