//! expect-stdout: 3
// #2520 shape 1: a user trait named One is a different trait from
// std.traits.One. Before trait identity, trait_lookup keyed traits by
// bare name, so this impl was checked against std's `fn one() -> Self`
// (no receiver): "undefined variable `self`" and "'X.one' is a
// function of the type".
trait One:
    fn one(self: &Self) -> i32

type X { v: i32 }

impl One for X:
    fn one(): self.v + 2

fn main:
    let x = X { v: 1 }
    print(x.one())
