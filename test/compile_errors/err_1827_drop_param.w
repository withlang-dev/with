//! expect-check-fail: call to `consume` mutates global `G` while `r` is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rules 1 and 7): a callee drops the value moved into its parameter when
// it returns; that Drop impl writes G while the caller's `r` views G.
// A call writes every global its callee writes, and a drop every global
// its Drop impls write (§2.4).

var G: List[str] = List.new()

type Tok:
    n: i32

impl Drop for Tok:
    move fn drop():
        for i in 0..64: G.push(f"item{i}")

fn consume(t: Tok): print(f"{t.n}")

fn main:
    G.push("first" ++ "!")
    let t = Tok { n: 1 }
    let r = G[0]
    consume(t)
    print(r)
