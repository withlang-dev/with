//! expect-check-fail: call to `show` mutates global `G` while its argument is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rules 1 and 7): a `HashMap[str, str]` global, viewed by
// an argument that views the whole global, written by a function stored in a field and called through it
// while the view is live.
// A call writes every global its callee writes, and a drop every global
// its Drop impls write (§2.4).

use std.collections.HashMap

var G: HashMap[str, str] = HashMap.new()

type H:
    f: fn() -> Unit

fn grow_g():
    for i in 0..64: G.insert(f"k{i}", f"v{i}")

fn show(r: &HashMap[str, str]):
    let h = H { f: grow_g }
    h.f()
    print(r.get("k").unwrap())

fn main:
    G.insert("k", "v" ++ "!")
    show(G)
