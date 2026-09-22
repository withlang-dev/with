//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// #1281 (found fixing it): the #605 element gate accepted only `NK_IDENT`
// elements, so `[s.r]` moved a field implicitly into a Vec literal — the
// base kept its bytes and `r` dropped once per copy (three drops of one
// value across `[s.r]`, `(s.r, 1)` and an array literal).
type R { n: i32 }
impl Drop for R:
    move fn drop(): print("drop")
type S { r: R, k: i32 }
fn main:
    let s = S { r: R { n: 2 }, k: 0 }
    let v: Vec[R] = [s.r]
    print(f"{v.len()} {s.k}")
