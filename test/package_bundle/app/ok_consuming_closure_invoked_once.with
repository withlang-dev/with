//! expect: ok

// #3401: apply invokes its callable parameter once, which nothing declares.
use shapes
type Tag { name: str }
impl Drop for Tag:
    move fn drop(): print("drop")
fn eat(t: Tag) -> i32: 1
fn main:
    let s = Shape { w: 1, h: 1, name: "a" }
    let t = Tag { name: "t" }
    print(apply(s, (x) => eat(t)))
