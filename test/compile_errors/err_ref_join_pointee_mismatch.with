//! expect-check-fail: `??` arms view `&i64` and `&i32`; a reference cannot convert its pointee
// The join picked the lower type id, `&i32`, and read four bytes of the
// map's i64 value: 4000000000 printed as -294967296.
use std.collections.HashMap

fn main:
    var m: HashMap[str, i64] = HashMap.new()
    m.insert("k", 4000000000)
    let z: i32 = 0
    let v = m.get("k") ?? &z
    print(f"{v}")
