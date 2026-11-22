//! expect-error: has no applicable implementation
// #2611 (§11.7): a plain operator method serves only its own side.
// `V.sub(f64)` defines `V - f64`; `2.0 - a` previously dispatched to
// it reversed and silently computed a.x - 2.0 (printed 8 where the
// source order says -8). Only ==/!= may dispatch from the right side,
// Eq being symmetric by contract.
type V { x: f64 }

impl V:
    fn sub(self: &Self, rhs: f64) -> V:
        V { x: self.x - rhs }

fn main:
    let a = V { x: 10.0 }
    let r = 2.0 - a
    print(r.x)
