// Consumer of the D39 demo bundle: built with --link-bundle <store>/wi_demo it
// sees only wi_demo.wi (declarations) and links the bundle's object.
use std.wi_demo
fn main:
    let p = Pair { a: 3, b: 4 }
    print(f"{add(p)} {take(p)} {table_at(2)} {K} {TABLE[1]}")
