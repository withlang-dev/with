//! expect-check-fail: the drop of `t` at the end of its scope mutates global `G` while `r` is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rules 1 and 7): a struct global with a `str` field, viewed by
// a local `let r = &G`, written by the Drop impl of a value dropped at the end of an inner scope
// while the view is live.
// A call writes every global its callee writes, and a drop every global
// its Drop impls write (§2.4).

type S:
    name: str
    n: i32

var G = S { name: "ab" ++ "cd", n: 1 }

type Tok:
    n: i32

impl Drop for Tok:
    move fn drop():
        G.name = "wx" ++ "yz"

fn main:
    let r = &G
    {
        let t = Tok { n: 1 }
        print(f"{t.n}")
    }
    print(r.name)
