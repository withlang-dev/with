//! expect-check-fail: `Reading` cannot be a map key: it holds a `f64`

// D96 (§11.7): a map literal's key is a key: structural `==` and no float.
type Reading { celsius: f64 }

fn main:
    let values = [Reading { celsius: 1.5 }: 10]
