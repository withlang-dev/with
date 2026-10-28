//! expect-error: has no applicable implementation for f64 and V
//! expect-error: `V.sub` serves `V - f64` only
//! expect-error: extend f64:
// D166 (§11.7): `V.sub(f64)` defines `V - f64` only. `2.0 - a` is
// f64's operator; the diagnostic names where that order is written.
type V { x: f64 }

impl V:
    fn sub(self: &Self, rhs: f64) -> V: V { x: self.x - rhs }

fn main:
    let a = V { x: 10.0 }
    let r = 2.0 - a
    print(r.x)
