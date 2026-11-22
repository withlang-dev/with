//! expect-check-fail: call to `m2` mutates global `G` while `k` is a live view into it

// #1819 (§9.1c: globals are places; §21.1 rule 1): a `HashMap[str, str]` global, viewed by
// the loop binding of a `for` over it, written by a callee's callee
// while the view is live.
// A call writes every global its callee writes.

use std.collections.HashMap

var G: HashMap[str, str] = HashMap.new()

fn m1():
    for i in 0..64: G.insert(f"k{i}", f"v{i}")

fn m2(): m1()

fn main:
    G.insert("k", "v" ++ "!")
    for (k, r) in G:
        m2()
        print(r)
        break
