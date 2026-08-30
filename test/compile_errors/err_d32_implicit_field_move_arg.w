//! expect-check-fail: a field never moves out implicitly

// D32 (§2.2): a bare non-Copy field in a consuming position is an implicit
// field move — an error at the move site, with fix-its for both intents.

type Holder { v: Vec[i32], n: i32 }

fn consume(v: Vec[i32]): assert(v.len() >= 0)

fn main:
    var xs: Vec[i32] = Vec.new()
    xs.push(7)
    let h = Holder { v: xs, n: 1 }
    consume(h.v)
