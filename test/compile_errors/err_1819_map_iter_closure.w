//! expect-check-fail: call to `f` mutates global `G` while `k` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a `HashMap[str, str]` global, viewed by
// the loop binding of a `for` over it, written by a closure run in between
// while the view is live.
// A call writes every global its callee writes.

use std.collections.HashMap

var G: HashMap[str, str] = HashMap.new()

fn main:
    G.insert("k", "v" ++ "!")
    let f: fn() -> Unit = () => { for i in 0..64: G.insert(f"k{i}", f"v{i}") }
    for (k, r) in G:
        f()
        print(r)
        break
