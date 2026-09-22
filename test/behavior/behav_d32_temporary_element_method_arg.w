//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// #1281: the method-call argument path only recorded consume sites for
// rooted arguments, so `s.m(make().1)` moved the element of a temporary
// with no D32 check at all.
type R { n: i32 }
impl Drop for R:
    move fn drop(): print("drop")
type S { k: i32 }
impl S:
    fn m(r: R) -> i32: r.n + self.k
fn make() -> (i32, R): (0, R { n: 1 })
fn main:
    let s = S { k: 1 }
    print(f"{s.m(make().1)}")
