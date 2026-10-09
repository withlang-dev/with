//! expect-check-fail: the drop of `t`'s old value at this assignment mutates global `G` while `r` is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rules 1 and 7): a reassignment drops the old value first; its Drop impl
// writes G while `r` views G.
// A call writes every global its callee writes, and a drop every global
// its Drop impls write (§2.4).

var G: List[str] = List.new()

type Tok:
    n: i32

impl Drop for Tok:
    move fn drop():
        for i in 0..64: G.push(f"item{i}")

fn main:
    G.push("first" ++ "!")
    var t = Tok { n: 1 }
    let r = G[0]
    t = Tok { n: 2 }
    print(f"{t.n}")
    print(r)
