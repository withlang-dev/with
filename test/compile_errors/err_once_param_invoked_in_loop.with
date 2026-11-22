//! expect-check-fail: is declared `once`, but this body may invoke it more than once

// §12.4 (D75): one call inside a loop may invoke a `once` parameter many
// times.
fn apply(f: once fn() -> str) -> str:
    var out = "".clone()
    for _ in 0..2:
        out = out ++ f()
    out

fn main:
    print(apply(() => "x".clone()))
