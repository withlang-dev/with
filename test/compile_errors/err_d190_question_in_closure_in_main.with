//! expect-check-fail: ? on Result requires the enclosing function to return Result
// §10.2 (D190): a `?` inside a closure in main is the closure's, not main's.
fn parse(s: str) -> Result[i32, str]:
    if s == "x": return Err("bad")
    7
fn main:
    let f = s => parse(s)? + 1
    print(f("3"))
