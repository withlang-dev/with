//! expect-error: undefined variable

fn main:
    let _ = match true
        true =>
            let hidden = 7
            hidden
        false => 0
    let _ = hidden
