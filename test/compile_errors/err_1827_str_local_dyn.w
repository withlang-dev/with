//! expect-check-fail: call to `run_dyn` mutates global `G` while `r` is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rules 1 and 7): a `str` global, viewed by
// a local `let r = &G`, written by the impl a callee's dyn call runs
// while the view is live.
// A call writes every global its callee writes, and a drop every global
// its Drop impls write (§2.4).

var G: str = "ab" ++ "cd"

trait Grow:
    fn grow(self: &Self)

type W { x: i32 }

impl Grow for W:
    fn grow(self: &Self):
        G = "wx" ++ "yz"

fn run_dyn(g: &dyn Grow): g.grow()

fn main:
    let r = &G
    run_dyn(W { x: 0 })
    print(r)
