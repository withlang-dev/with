//! expect-error: expected an indented block after '=>'

// #1391 (§29.13 Form 2): an arm body opened by `=>` at the end of the line
// sits deeper than the arms.
fn name(n: i32) -> str:
    match n:
        0 =>
        "zero"
        _ => "many"

fn main:
    print(name(0))
