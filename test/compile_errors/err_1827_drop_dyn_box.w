//! expect-check-fail: the drop of `c` at the end of its scope mutates global `G` while `r` is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rules 1 and 7; §2.4): the drop of
// a `Box[dyn Named]` runs the drop of whatever implementor it holds — any
// implementor of `Named` in this compilation — and `Tok`'s Drop impl
// reallocates `G` at the end of `c`'s scope while `r` views its first
// element.

use std.box.Box

var G: List[str] = List.new()

trait Named:
    fn name(self: &Self) -> i32

type Tok:
    n: i32

impl Named for Tok:
    fn name(self: &Self) -> i32: self.n

impl Drop for Tok:
    move fn drop():
        for i in 0..64: G.push(f"item{i}")

fn main:
    G.push("first" ++ "!")
    let b: Box[dyn Named] = Box.new(Tok { n: 1 })
    let r = G[0]
    {
        let c = b
        print(f"{c.name()}")
    }
    print(r)
