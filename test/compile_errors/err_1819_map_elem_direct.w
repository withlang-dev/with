//! expect-check-fail: cannot mutate `G` while `r` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a `HashMap[str, str]` global, viewed by
// an element view, written directly
// while the view is live.
// A call writes every global its callee writes.

use std.collections.HashMap

var G: HashMap[str, str] = HashMap.new()

fn main:
    G.insert("k", "v" ++ "!")
    let r = G.get("k").unwrap()
    for i in 0..64: G.insert(f"k{i}", f"v{i}")
    print(r)
