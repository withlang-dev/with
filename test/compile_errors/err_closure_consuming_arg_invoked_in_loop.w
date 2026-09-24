//! expect-check-fail: invokes its parameter more than once

// D63 (§12.4): one call site inside a loop invokes the parameter many
// times, so a consuming closure may not be passed to it.
fn repeat(f: fn() -> str, n: i32) -> str:
    var out = "".clone()
    for _ in 0..n:
        out = out ++ f()
    out

fn main:
    let s = "abc".clone()
    print(repeat(() => s, 2))
