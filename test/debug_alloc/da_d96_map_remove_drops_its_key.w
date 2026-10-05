//! expect-debug-alloc: leak count=0
//! expect-stdout: 0 0
// `remove(key: K)` consumes its key: the stored key and the probe are both
// dropped. The probe leaked.
use std.collections.HashMap
use std.collections.HashSet

fn main:
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("a".to_lower(), 1)
    let _ = m.remove("a".to_lower())
    var s: HashSet[str] = HashSet.new()
    s.insert("b".to_lower())
    let _ = s.remove("b".to_lower())
    let _ = s.remove("c".to_lower())
    print(f"{m.len()} {s.len()}")
