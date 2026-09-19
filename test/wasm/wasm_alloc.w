//! expect-stdout: sum=14999850000
//! expect-stdout: len=4000
//! expect-stdout: two=2
//! expect-stdout: f=6.5 0.33333333333333

use std.collections.HashMap

fn main:
    var v: Vec[i64] = Vec.new()
    for i in 0..100000:
        v.push(i as i64 * 3)
    var total: i64 = 0
    for i in 0..v.len() as i32:
        total = total + v[i]
    print(f"sum={total}")
    var s = ""
    for i in 0..2000:
        s = s ++ "ab"
    print(f"len={s.len()}")
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("one", 1)
    m.insert("two", 2)
    let two = m.get("two")
    if two.is_some():
        print(f"two={two.unwrap()}")
    let x: f64 = 3.25
    print(f"f={x * 2.0} {1.0 / 3.0}")
