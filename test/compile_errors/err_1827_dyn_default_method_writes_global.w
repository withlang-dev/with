//! expect-check-fail: call to `dyn Grow.grow` mutates global `G` while `r` is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rule 1): an impl that keeps the
// trait's default body runs it through the vtable; the default body is that
// impl's method, and it reallocates `G` while `r` views its first element.
var G: List[str] = List.new()

trait Grow:
    fn tag(self: &Self) -> i32
    fn grow(self: &Self):
        for i in 0..64: G.push(f"item{i}")

type W { x: i32 }

impl Grow for W:
    fn tag(self: &Self) -> i32: self.x

fn run(g: &dyn Grow):
    let r = G[0]
    g.grow()
    print(r)

fn main:
    G.push("first" ++ "!")
    run(W { x: 0 })
