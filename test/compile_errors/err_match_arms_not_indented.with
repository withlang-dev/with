//! expect-error: expected an indented block after ':'

// #1391 (§29.13 Form 2): a match's arms are its indented body.
fn name(n: i32) -> str:
    match n:
    0 => "zero"
    _ => "many"

fn main:
    print(name(0))
