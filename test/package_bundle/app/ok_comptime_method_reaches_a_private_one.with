//! expect: ok

// D227: a `comptime` method that reaches a private method of its own
// package is evaluated in the importer, from source and from the bundle.
use shapes

const SIX: i32 = comptime Tally { n: 3 }.doubled()

fn main:
    print(f"{SIX}")
