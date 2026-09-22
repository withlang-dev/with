//! expect-check-fail: a pattern that disarms `R`'s Drop must account for every field; add `fd: _`

// #1272: inside the type's own `move fn` a destructure is the visible disarm
// of Drop, and must be total — every field named or explicitly `_`. A `..`
// rest leaves fields unaccounted for and is an error naming them.

var count: i32 = 0
type R { repr: i32, fd: i32 }
impl Drop for R:
    move fn drop(): count = count + 1
impl R:
    move fn take() -> i32:
        let { repr, .. } = self
        repr

fn main:
    let r = R { repr: 7, fd: 3 }
    print(f"{r.take()}")
