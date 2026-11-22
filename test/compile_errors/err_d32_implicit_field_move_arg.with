//! expect-check-fail: a field never moves out implicitly

// D32 (§2.2): a bare non-Copy field in a consuming position is an implicit
// field move — an error at the move site, with fix-its for both intents.

type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
type Holder { v: List[Tok], n: i32 }

fn consume(v: List[Tok]): assert(v.len() >= 0)

fn main:
    var xs: List[Tok] = List.new()
    xs.push(Tok { id: 7 })
    let h = Holder { v: xs, n: 1 }
    consume(h.v)
