//! expect-check-fail: call to `grow` mutates global `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a pipeline stage is a call (§9.6), and `grow` writes G
// while an element view of G is live.
// A call writes every global its callee writes.

var G: Vec[str] = Vec.new()

fn grow(n: i32) -> i32:
    for i in 0..64: G.push(f"item{i}")
    n

fn main:
    G.push("first" ++ "!")
    let r = G[0]
    let k = 3 |> grow()
    print(f"{k}")
    print(r)
