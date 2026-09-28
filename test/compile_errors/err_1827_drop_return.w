//! expect-check-fail: the drop of `t` at this `return` mutates global `G` while a view into it outlives the drop

// #1827 (§9.1c: globals are places; §21.1 rules 1 and 7): a `return` drops the body's bindings after the returned
// view of G is made; their Drop impl writes G under it.
// A call writes every global its callee writes, and a drop every global
// its Drop impls write (§2.4).

var G: Vec[str] = Vec.new()

type Tok:
    n: i32

impl Drop for Tok:
    move fn drop():
        for i in 0..64: G.push(f"item{i}")

fn first(c: bool) -> &str:
    let t = Tok { n: 1 }
    if c:
        return G[0]
    print(f"{t.n}")
    G[0]

fn main:
    G.push("first" ++ "!")
    print(first(true))
