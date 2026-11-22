//! expect-debug-alloc: leak count=0
//! expect-stdout: a c bb
//! expect-stdout: first:x rest:y,z
//! expect-stdout: keep q
//! expect-stdout: 2

// #1366: a tuple rest `..name` moves each owned element it covers into the
// rest tuple exactly once, and a bare `..` drops the owned elements it skips.
// A guard that fails puts the moved elements back before the next arm binds
// them again (no double free, no leak).
fn describe(t: (str, str, str)) -> str:
    match t:
        (h, ..rest) if rest.0.len() > 5 => "long " ++ h
        (h, ..rest) => f"first:{h} rest:{rest.0},{rest.1}"

fn main:
    let (x, ..rest) = ("a", "bb", "c")
    let (mid, end) = rest
    print(f"{x} {end} {mid}")
    print(describe(("x", "y", "z")))
    let (k, .., last) = ("keep", "skip", "skip2", "q")
    print(f"{k} {last}")
    var n = 0
    let (_, ..tail) = ("v", 1, "w")
    n = n + tail.0 + tail.1.len() as i32
    print(f"{n}")
