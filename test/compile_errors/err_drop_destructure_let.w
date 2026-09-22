//! expect-check-fail: keep it whole (`let t = r`) or read a field (`r.repr`); only a `move fn` of `R` may take it apart

// #1272: a `let` struct pattern over a value whose type implements Drop would
// skip its destructor. Outside the type's own `move fn` methods that is an
// error, with the two spellings that keep Drop running as the fix-it.

var count: i32 = 0
type R { repr: i32 }
impl Drop for R:
    move fn drop(): count = count + 1

fn main:
    let r = R { repr: 7 }
    let { repr } = r
    print(f"{repr}")
