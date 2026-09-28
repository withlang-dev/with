//! expect-check-fail: call to `show` mutates global `G` while its argument is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rules 1 and 7): a struct global with a `str` field, viewed by
// an argument that views the whole global, written by the impl a callee's dyn call runs
// while the view is live.
// A call writes every global its callee writes, and a drop every global
// its Drop impls write (§2.4).

type S:
    name: str
    n: i32

var G = S { name: "ab" ++ "cd", n: 1 }

trait Grow:
    fn grow(self: &Self)

type W { x: i32 }

impl Grow for W:
    fn grow(self: &Self):
        G.name = "wx" ++ "yz"

fn run_dyn(g: dyn Grow): g.grow()

fn show(r: &S):
    run_dyn(W { x: 0 })
    print(r.name)

fn main:
    show(G)
