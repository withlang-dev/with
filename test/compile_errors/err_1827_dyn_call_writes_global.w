//! expect-check-fail: call to `dyn Grow.grow` mutates global `G` while `r` is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rule 1): a call through a vtable
// runs one of the method's impls, which one decided when the program runs:
// it counts as running every impl of the method in this compilation. `W`'s
// `grow` reallocates `G` while `r` views its first element.
var G: Vec[str] = Vec.new()

trait Grow:
    fn grow(self: &Self)

type W { x: i32 }

impl Grow for W:
    fn grow(self: &Self):
        for i in 0..64: G.push(f"item{i}")

type Quiet { x: i32 }

impl Grow for Quiet:
    fn grow(self: &Self): print("quiet")

fn run(g: &dyn Grow):
    let r = G[0]
    g.grow()
    print(r)

fn main:
    G.push("first" ++ "!")
    run(Quiet { x: 0 })
    run(W { x: 0 })
