//! expect-check-fail: call to `show` mutates global `G` while its argument is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rules 1 and 7): a `HashMap[str, str]` global, viewed by
// an argument that views a value in it (a `&str` parameter), written by the Drop impl of a value dropped at the end of an inner scope
// while the view is live.
// A call writes every global its callee writes, and a drop every global
// its Drop impls write (§2.4).

use std.collections.HashMap

var G: HashMap[str, str] = HashMap.new()

type Tok:
    n: i32

impl Drop for Tok:
    move fn drop():
        for i in 0..64: G.insert(f"k{i}", f"v{i}")

fn show(r: &str):
    {
        let t = Tok { n: 1 }
        print(f"{t.n}")
    }
    print(r)

fn main:
    G.insert("k", "v" ++ "!")
    show(G.get("k").unwrap())
