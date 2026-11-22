//! expect-error: `slot_count` walks a map's storage and is internal to std.collections
// D44: a map's slot positions include removed entries and are no API; a
// program traverses with iter(), keys() or values().
use std.collections

fn main:
    var m: HashMap[i32, i32] = HashMap.new()
    m.insert(1, 2)
    print(m.slot_count())
