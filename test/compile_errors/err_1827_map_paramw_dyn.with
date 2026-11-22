//! expect-check-fail: call to `show` mutates global `G` while its argument is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rules 1 and 7): a `HashMap[str, str]` global, viewed by
// an argument that views the whole global, written by the impl a callee's dyn call runs
// while the view is live.
// A call writes every global its callee writes, and a drop every global
// its Drop impls write (§2.4).

use std.collections.HashMap

var G: HashMap[str, str] = HashMap.new()

trait Grow:
    fn grow(self: &Self)

type W { x: i32 }

impl Grow for W:
    fn grow(self: &Self):
        for i in 0..64: G.insert(f"k{i}", f"v{i}")

fn run_dyn(g: &dyn Grow): g.grow()

fn show(r: &HashMap[str, str]):
    run_dyn(W { x: 0 })
    print(r.get("k").unwrap())

fn main:
    G.insert("k", "v" ++ "!")
    show(G)
