//! expect-stdout: alpha=1 beta=2
//! expect-stdout: 2 0
// D44 (#2191): a map's entries move out through the C backend too
// (with_hashmap_take_at), in insertion order (D96).
use std.collections

var m: HashMap[str, i32] = HashMap.new()
m.insert("alpha".to_owned(), 1)
m.insert("beta".to_owned(), 2)
var parts: List[str] = List.new()
for (k, v) in m.drain(): parts.push(f"{k}={v}")
print(parts.join(" "))
print(f"{parts.len()} {m.len()}")
