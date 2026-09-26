//! expect-stdout: 7 7 2 1
// D52 (§9.1c): a `const` is a value, not a place — every use materializes
// it, so passing it to a consuming parameter transfers nothing and a later
// use is not a use of a moved value. Direct (`take(NAME)`), through a
// borrowing free function into a consuming method (build.w's
// `.input(build_owned_text(FIXPOINT_STAGE2_UNITS))`), and on the method
// path (`.extra_output(NAME)`, the #1588 shape that refused build.w).
const NAME: str = "a.units"
fn owned(s: &str): s ++ ""
fn take(s: str) -> i64: s.len()
type T { inputs: Vec[str], extra: Vec[str] }
impl T:
    move fn input(path: str) -> T:
        var t = self
        t.inputs.push(path)
        t
    move fn extra_output(path: str) -> T:
        var t = self
        t.extra.push(path)
        t
fn main:
    let a = take(NAME)
    let b = take(NAME)
    var t = T { inputs: Vec.new(), extra: Vec.new() }
    t = t.input(owned(NAME)).input(owned(NAME))
    t = t.extra_output(NAME)
    print(f"{a} {b} {t.inputs.len()} {t.extra.len()}")
