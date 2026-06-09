//! expect-error: expected ':' or '{' to introduce body

fn main:
    let value = Some(1)
    let y = if let Some(x) = value then x else: 0
    let _ = y
