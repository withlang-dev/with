//! expect-check-fail: the drop of `t` at the end of its scope mutates global `G` while a view into it outlives the drop

// #1827 (§9.1c: globals are places; §21.1 rules 1 and 7): the body's bindings drop after its tail value, a view of
// G, is made; their Drop impl writes G under it.
// A call writes every global its callee writes, and a drop every global
// its Drop impls write (§2.4).

var G: List[str] = List.new()

type Tok:
    n: i32

impl Drop for Tok:
    move fn drop():
        for i in 0..64: G.push(f"item{i}")

fn first() -> &str:
    let t = Tok { n: 1 }
    print(f"{t.n}")
    G[0]

fn main:
    G.push("first" ++ "!")
    print(first())
