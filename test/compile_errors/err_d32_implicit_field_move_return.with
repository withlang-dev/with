//! expect-check-fail: a field never moves out implicitly

// D32 (§2.2): return positions demand an owned value — a bare non-Copy
// field behind `return` is an implicit field move and errors at the site.

type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
type Holder { v: List[Tok], n: i32 }

fn take(h: Holder) -> List[Tok]:
    return h.v

fn main:
    var xs: List[Tok] = List.new()
    xs.push(Tok { id: 7 })
    let got = take(Holder { v: xs, n: 1 })
    assert(got.len() == 1)
