//! expect-stdout: 3 -1 7 0

use std.collections.HashMap

// D114 (§4.2.1 rule 3): an untyped literal fallback of `??` takes the
// payload's numeric type, through a view too; it is not the isize default.
fn take(x: i32): x

fn main:
    var m: HashMap[i32, i32] = HashMap.new()
    m.insert(1, 3)
    let hit = m.get(1) ?? -1
    let miss = m.get(2) ?? -1
    let some: Option[i32] = Some(7)
    let none: Option[i32] = None
    print(f"{take(hit)} {take(miss)} {take(some ?? 0)} {take(none ?? 0)}")
