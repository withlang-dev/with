//! expect-check-fail: a field never moves out implicitly

// D32 (§2.2): the fn-body tail is a return position. Before D32 this shape
// passed check and double-freed at runtime (the borrow-base tail copied the
// Vec and both owners dropped it).

type Holder { v: Vec[i32], n: i32 }

impl Holder:
    fn grab(self: &Self) -> Vec[i32]: self.v

fn main:
    var xs: Vec[i32] = Vec.new()
    xs.push(7)
    let h = Holder { v: xs, n: 1 }
    let got = h.grab()
    assert(got.len() == 1)
