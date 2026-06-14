//! expect-check-fail: non-exhaustive match: missing variant 'None'

fn main:
    let value = Some(1) |> match:
        Some(x) => x
    let _ = value
