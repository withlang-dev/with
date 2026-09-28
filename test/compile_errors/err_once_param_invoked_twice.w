//! expect-check-fail: is declared `once`, but this body may invoke it more than once

// §12.4 (D75): "The compiler rejects a body that may invoke a `once`
// parameter more than once" — whatever its callers pass.
fn apply(f: once fn() -> str) -> str:
    let a = f()
    a ++ f()

fn main:
    print(apply(() => "x".clone()))
