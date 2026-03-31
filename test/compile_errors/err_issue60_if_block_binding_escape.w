//! expect-error: undefined variable

fn main:
    let _ = if true:
        let hidden = 1
        hidden
    else:
        2
    let _ = hidden
