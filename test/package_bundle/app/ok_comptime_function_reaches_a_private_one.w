//! expect: ok

// D227: a `comptime` function that reaches a private function of its own
// package is evaluated in the importer; the interface carries both bodies.
use shapes

const EIGHT: i32 = comptime cubed(2)

fn main:
    print(f"{EIGHT}")
