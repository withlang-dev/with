//! expect-check-fail: call to `show` mutates global `G` while its argument is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rules 1 and 7): a `str` global, viewed by
// an argument that views a value in it (a `&str` parameter), written by a function stored in a field and called through it
// while the view is live.
// A call writes every global its callee writes, and a drop every global
// its Drop impls write (§2.4).

var G: str = "ab" ++ "cd"

type H:
    f: fn() -> Unit

fn grow_g():
    G = "wx" ++ "yz"

fn show(r: &str):
    let h = H { f: grow_g }
    h.f()
    print(r)

fn main:
    show(G)
