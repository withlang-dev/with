//! expect-error: this closure consumes its capture and may be invoked once

// #3401: each invokes its callable parameter twice.
use shapes
type Tag { name: str }
impl Drop for Tag:
    move fn drop(): print("drop")
fn eat(t: Tag) -> i32: 1
fn main:
    let xs = [Shape { w: 1, h: 1, name: "a" }]
    let t = Tag { name: "t" }
    print(each(xs, (s) => eat(t)))
