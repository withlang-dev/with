//! expect-check-fail: ? operator requires an Option, Result, or a type implementing Try

type Plain { value: i32 }

fn plain() -> Plain:
    Plain { value: 1 }

fn main:
    let _ = plain()?
