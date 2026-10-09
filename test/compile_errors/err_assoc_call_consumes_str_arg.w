//! expect-check-fail: use of moved value
// #1588: a plain owned parameter of an associated call consumes its argument
// exactly as a free call's does (§3.8); the later read is a use after move.
// A List, not a str: a str is a value and is copied (D111).
type T { n: i64 }
fn T.make(v: List[i32]) -> T: T { n: v.len() }
fn main:
    let p: List[i32] = [1, 2, 3]
    let t = T.make(p)
    print(f"assoc: [{p.len()}] {t.n}")
