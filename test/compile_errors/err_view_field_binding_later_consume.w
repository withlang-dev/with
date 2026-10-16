//! expect-error: cannot consume read-only view binding `observed`

// D27 E3: an unannotated field binding is legal, but its later by-value use is
// an owned demand and must fail at the consume site.

type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
type Outer { v: List[Tok], n: i32 }

fn consume(v: List[Tok]) -> i64: v.len()

fn main:
    var o = Outer { v: List.new(), n: 7 }
    o.v.push(Tok { id: 1 })
    let observed = (&o).v
    assert(consume(observed) == 1)
