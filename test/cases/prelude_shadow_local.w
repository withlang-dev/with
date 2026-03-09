//! expect-stdout: ok

// Test: local function definitions shadow prelude-provided functions.
// The prelude imports std.iter which provides map(Vec[str], fn(str)->i32).
// A local fn map with a different signature must shadow it silently.

fn map(x: i32) -> i32:
    x * 2

fn filter(x: i32) -> i32:
    x + 1

fn sum(a: i32, b: i32) -> i32:
    a + b

fn main:
    assert(map(5) == 10)
    assert(filter(5) == 6)
    assert(sum(3, 4) == 7)
    println("ok")
