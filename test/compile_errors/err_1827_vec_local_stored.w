//! expect-check-fail: call to `h.f` mutates global `G` while `r` is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rules 1 and 7): a `Vec[str]` global, viewed by
// a local `let r = &G`, written by a function stored in a field and called through it
// while the view is live.
// A call writes every global its callee writes, and a drop every global
// its Drop impls write (§2.4).

var G: Vec[str] = Vec.new()

type H:
    f: fn() -> Unit

fn grow_g():
    for i in 0..64: G.push(f"item{i}")

fn main:
    G.push("first" ++ "!")
    let h = H { f: grow_g }
    let r = &G
    h.f()
    print(r[0])
