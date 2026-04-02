//! expect-error: await requires async context

fn main:
    let x = 42
    let y = x.await
