//! expect-check-fail: call to `h.f` mutates global `G` while `r` is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rules 1 and 7): a `HashMap[str, str]` global, viewed by
// a local `let r = &G`, written by a function stored in a field and called through it
// while the view is live.
// A call writes every global its callee writes, and a drop every global
// its Drop impls write (§2.4).

use std.collections.HashMap

var G: HashMap[str, str] = HashMap.new()

type H:
    f: fn() -> Unit

fn grow_g():
    for i in 0..64: G.insert(f"k{i}", f"v{i}")

fn main:
    G.insert("k", "v" ++ "!")
    let h = H { f: grow_g }
    let r = &G
    h.f()
    print(r.get("k").unwrap())
