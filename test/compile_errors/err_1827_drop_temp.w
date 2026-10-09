//! expect-check-fail: the drop of this temporary at the end of its statement mutates global `G` while `r` is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rules 1 and 7): a temporary drops at the end of its statement; its Drop
// impl writes G while `r` views G.
// A call writes every global its callee writes, and a drop every global
// its Drop impls write (§2.4).

var G: List[str] = List.new()

type Tok:
    n: i32

impl Drop for Tok:
    move fn drop():
        for i in 0..64: G.push(f"item{i}")

fn make(n: i32) -> Tok: Tok { n }

fn main:
    G.push("first" ++ "!")
    let r = G[0]
    let n = make(1).n
    print(f"{n}")
    print(r)
