// Consumer of the D39 demo bundle: built with --link-bundle <store>/wi_demo it
// sees only wi_demo.wi (declarations) and links the bundle's object.
use std.wi_demo
fn main:
    var p = Pair { a: 3, b: 4 }
    let s = p.sum()
    p.scale(2)
    unsafe { set_first(&raw mut p, 10) }
    let a = add(p)
    let q = Pair { a: 1, b: 2 }
    let w = q.into_word()
    let xs: [3]i32 = [1, 2, 3]
    COUNTER = COUNTER + 5
    print(f"{a} {s} {take(p)} {table_at(2)} {K} {TABLE[1]} {sum_slice(xs)} {level_value(Level.High)} {GREETING.len()} {w} {COUNTER}")
