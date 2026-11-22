//! expect-check-fail: a field never moves out implicitly

// D32 (§2.2): the fn-body tail is a return position. Before D32 this shape
// passed check and double-freed at runtime (the borrow-base tail copied the
// List and both owners dropped it).

type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
type Holder { v: List[Tok], n: i32 }

impl Holder:
    fn grab(self: &Self) -> List[Tok]: self.v

fn main:
    var xs: List[Tok] = List.new()
    xs.push(Tok { id: 7 })
    let h = Holder { v: xs, n: 1 }
    let got = h.grab()
    assert(got.len() == 1)
