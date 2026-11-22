//! expect-error: `Reading` cannot be a map key: it holds a `f64`

// D96 (§11.7): a map comprehension's key is a key: structural `==` and no
// float.
type Reading { celsius: f64 }

fn main:
    let _bad = [Reading { celsius: x as f64 }: x for x in 0..3]
