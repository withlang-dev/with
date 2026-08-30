//! expect-stdout: ok

// D32 (§2.2) × D27 R3: a binding names what's there — the unannotated let of
// a field binds the view, and a view-typed return escapes; neither is a
// field move, so neither trips the D32 error.

type Holder { v: Vec[i32], n: i32 }

impl Holder:
    fn peek(self: &Self) -> &Vec[i32]: self.v

fn main:
    var xs: Vec[i32] = Vec.new()
    xs.push(7)
    let h = Holder { v: xs, n: 1 }
    let view = h.v
    assert(view.len() == 1)
    assert(h.peek().len() == 1)
    assert(h.v.get(0) == 7)
    print("ok")
