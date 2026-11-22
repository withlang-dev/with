//! expect-check-fail: cannot implement sealed trait 'SealedMarker' outside its defining module
use coherence.sealed_mod

type LocalThing {
    n: i32,
}

impl SealedMarker for LocalThing:
    fn tag(self: &Self) -> i32: self.n

fn main:
    let _t = LocalThing { n: 1 }
