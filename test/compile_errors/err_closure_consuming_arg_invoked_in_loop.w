//! expect-check-fail: invokes its parameter more than once

// D63 (§12.4): one call site inside a loop invokes the parameter many
// times, so a consuming closure may not be passed to it.
// A List capture, not a str: a str capture is copied (D111).
fn repeat(f: fn() -> List[i32], n: i32) -> i64:
    var out: i64 = 0
    for _ in 0..n:
        out = out + f().len()
    out

fn main:
    let s: List[i32] = [1, 2, 3]
    print(repeat(() => s, 2))
