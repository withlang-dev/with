//! expect-check-fail: keep it whole (`let t = s`) or read a field (`s.repr`); only a `move fn` of `R` may take it apart

// #1272: a `match` arm pattern that takes a Drop value apart shares the `let`
// rule — an error outside the type's own `move fn` methods. A `_` arm keeps
// the value whole and is unaffected.

var count: i32 = 0
type R { repr: i32 }
impl Drop for R:
    move fn drop(): count = count + 1

fn main:
    let s = R { repr: 8 }
    match s:
        R { repr: v } => print(f"{v}")
