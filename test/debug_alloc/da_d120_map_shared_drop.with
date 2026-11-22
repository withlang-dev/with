//! expect-debug-alloc: leak count=0
//! expect-stdout: a 2 b 3 c 2
//! expect-stdout: a.k v b.k v2
//! expect-stdout: ok

// D120 stage 2: three holders of one map table (a HashMap of str keys and
// str values), one of them written after the copy. The shared table is
// freed once, by its last holder; the copied table retains every str it
// carries, so each str is released exactly as many times as it was held.
use std.collections.HashMap
use std.collections.HashSet

fn main:
    var a: HashMap[str, str] = HashMap.new()
    a.insert("k", "v")
    a.insert("k2", "v2")
    var b = a
    var c = a
    b.insert("k3", "v3")
    b.insert("k", "v2")
    print(f"a {a.len()} b {b.len()} c {c.len()}")
    print(f"a.k {a.get(\"k\").unwrap()} b.k {b.get(\"k\").unwrap()}")
    var set: HashSet[str] = HashSet.new()
    set.insert("s")
    var set2 = set
    set2.insert("t")
    print(f"{set.len() == 1 and set2.len() == 2}".replace("true", "ok"))
