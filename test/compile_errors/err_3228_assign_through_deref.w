//! expect-check-fail: it is reached through a `Deref` implementation, which lends a shared view
// #3228: `w.n = 5` where `n` is found through `Deref.deref` wrote through a
// shared `&Rec`. There is no mutable deref; the assignment is refused.
type Rec { data: *mut i32, n: i32 }
type Wrap { repr: Rec, live: bool }
impl Deref[Rec] for Wrap:
    fn deref(self: &Self) -> &Rec: &self.repr

fn main:
    var w = Wrap { repr: Rec { data: null, n: 4 }, live: true }
    w.n = 5
    print(f"{w.n}")
