//! expect-check-fail: the drop of `t` at the end of its scope mutates global `G` while `r` is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rules 1 and 7): a `List[str]` global, viewed by
// an element view, written by the Drop impl of a value dropped at the end of an inner scope
// while the view is live.
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
    let r = G[0]
    {
        let t = Tok { n: 1 }
        print(f"{t.n}")
    }
    print(r)
