//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// #1281 (found fixing it): the tuple-literal element gate accepted only
// `NK_IDENT` elements, so `(s.r, 1)` moved a field implicitly (§2.2, D32).
type R { n: i32 }
impl Drop for R:
    move fn drop(): print("drop")
type S { r: R, k: i32 }
fn main:
    let s = S { r: R { n: 2 }, k: 0 }
    let t = (s.r, 1)
    print(f"{t.1} {s.k}")
