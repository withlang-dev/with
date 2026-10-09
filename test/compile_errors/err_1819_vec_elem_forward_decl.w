//! expect-check-fail: call to `later` mutates global `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): the callee that writes G is declared after its caller:
// the caller's view is judged once every body is checked.
// A call writes every global its callee writes.

var G: List[str] = List.new()

fn main:
    G.push("first" ++ "!")
    let r = G[0]
    later()
    print(r)

fn later():
    for i in 0..64: G.push(f"item{i}")
