//! expect-check-fail: cannot move out of global `g`

// #1242: a consuming parameter and a `move self` receiver take the global's
// value the same way a binding does.

type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
var g: List[Tok] = List.new()

fn consume(v: List[Tok]) -> i64: v.len()

fn main:
    g.push(Tok { id: 1 })
    print(f"{consume(g)}")
