//! expect-check-fail: call to `show` mutates global `G` while its argument is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a `HashMap[str, str]` global, viewed by
// an argument that views the whole global, written by a closure run in between
// while the view is live.
// A call writes every global its callee writes.

use std.collections.HashMap

var G: HashMap[str, str] = HashMap.new()

fn show(r: &HashMap[str, str]):
    let f: fn() -> Unit = () => { for i in 0..64: G.insert(f"k{i}", f"v{i}") }
    f()
    print(r.get("k").unwrap())

fn main:
    G.insert("k", "v" ++ "!")
    show(G)
