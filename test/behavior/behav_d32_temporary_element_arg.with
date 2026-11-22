//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// #1281: an element of a statement temporary is still a field, and §2.2
// holds "anywhere, in any context ... every other base". Tail position
// already refused `make().1`; the call-argument position accepted the
// same expression. Both refuse now, with a help that fits a temporary.
type R { n: i32 }
impl Drop for R:
    move fn drop(): print("drop")
fn make() -> (i32, R): (0, R { n: 1 })
fn take(r: R) -> i32: r.n
fn main:
    print(f"{take(make().1)}")
