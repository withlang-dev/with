//! expect-check-fail: use of moved value
// #1588: a plain `str` parameter of an associated call consumes its argument
// exactly as a free call's does (§3.8); the later read is a use after move.
type T { n: i64 }
fn T.make(s: str) -> T: T { n: s.len() }
fn main:
    let p = "abc"
    let t = T.make(p)
    print(f"assoc: [{p}] {t.n}")
