//! expect-stdout: ok

// #2225 (D71, D105): `str.trim()` is a view, like `trim_start()` and
// `trim_end()` — O(1), no allocation — and a caller that keeps the result
// past the source spells `.to_owned()`.
fn width(s: &str) -> i64: s.len()

fn keep(line: &str) -> str: line.trim().to_owned()

fn main:
    let padded = "  \t hello, world \n "
    let t = padded.trim()
    assert(t == "hello, world")
    assert(width(t) == 12)
    assert(padded.trim_start().trim_end() == t)
    assert("".trim() == "")
    assert("   ".trim() == "")
    assert("x".trim() == "x")
    let owned = keep("  kept  ")
    assert(owned == "kept")
    // Comptime runs the same body (D104).
    const C: str = comptime "  const  ".trim().to_owned()
    assert(C == "const")
    print("ok")
