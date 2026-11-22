//! expect-stdout: 3 12
//! expect-stdout: ok

// #2220: a plain function that builds a List without writing its element
// type is comptime-callable. The const fold reaches `count` before Sema's
// body pass, so the evaluator has Sema type the body on demand; `v`'s
// element type comes from its uses (D93), exactly as it does at runtime.
use std.collections.HashMap

fn count() -> i32:
    var v = List.new()
    v.push(7)
    v.push(8)
    v.push(9)
    v.len() as i32

fn total() -> i32:
    var m = HashMap.new()
    m.insert("a", 5)
    m.insert("b", 7)
    var s = 0
    for (_, x) in m: s = s + x
    s as i32

const C: i32 = comptime count()
const T: i32 = comptime total()

fn main:
    print(f"{C} {T}")
    print("ok")
