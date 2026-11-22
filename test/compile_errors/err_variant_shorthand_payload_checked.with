//! expect-error: unknown method 'no_such'

// #933: a `.Variant(args)` shorthand checks its payload arguments like the
// bare `Variant(args)` call does — an ill-typed payload is a diagnostic
// here, never a silent hole MirLower fills with unit.
fn f(v: &List[i32]) -> Option[&i32]: .Some(v[0].no_such())
fn main:
    let xs: List[i32] = [1]
    let _ = f(xs)
