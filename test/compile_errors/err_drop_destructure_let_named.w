//! expect-check-fail: keep it whole (`let t = r`) or read a field (`r.repr`); only a `move fn` of `R` may take it apart

// #1272 / #1299: the NAMED struct pattern in `let` (`let R { repr } = r`) is
// the same pattern form as the anonymous `let { repr } = r`, so it is refused
// on a Drop value outside the type's own `move fn` with the same fix-it.

var count: i32 = 0
type R { repr: i32 }
impl Drop for R:
    move fn drop(): count = count + 1

fn main:
    let r = R { repr: 7 }
    let R { repr } = r
    print(f"{repr}")
