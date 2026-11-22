//! expect-check-fail: keep it whole (`let t = r`) or read a field (`r.repr`); only a `move fn` of `R` may take it apart

// #1272: `if let` desugars to a match, so its pattern over a Drop value is
// rejected by the same rule as `let` and `match`.

var count: i32 = 0
type R { repr: i32 }
impl Drop for R:
    move fn drop(): count = count + 1

fn main:
    let r = R { repr: 9 }
    if let R { repr } = r:
        print(f"{repr}")
