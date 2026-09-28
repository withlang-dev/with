//! expect-check-fail: is declared `once`, but `twice` may invoke its parameter more than once

// §12.4 (D75): passing a `once` parameter on to one that may be invoked
// more than once is a body that may invoke it more than once.
fn twice(f: fn() -> str) -> str:
    let a = f()
    a ++ f()

fn apply(f: once fn() -> str) -> str: twice(f)

fn main:
    print(apply(() => "x".clone()))
