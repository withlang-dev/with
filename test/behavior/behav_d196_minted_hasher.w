//! expect-stdout: 3 two
//! expect-stdout: 10 20 30
//! expect-stdout: 2 true false
//! expect-stdout: 7 8 9
//! expect-stdout: c 1

// D196 (§11.7): a map whose keys are IDs this program minted names the
// `Minted` hasher where it is declared. Everything but the hash is the
// same map: insert, get, remove, insertion-ordered traversal, a set, a
// literal.
use std.collections.HashMap
use std.collections.HashSet
use std.collections.Minted

fn main:
    var ids: HashMap[i32, str, Minted] = HashMap.new()
    ids.insert(10, "one")
    ids.insert(20, "two")
    ids.insert(30, "three")
    print(f"{ids.len()} {ids.get(20).unwrap()}")
    var keys = ""
    for (k, _) in ids: keys = keys ++ f"{k} "
    print(keys.trim())
    var seen: HashSet[i64, Minted] = HashSet.new()
    seen.insert(5)
    seen.insert(6)
    seen.insert(5)
    print(f"{seen.len()} {seen.contains(6)} {seen.contains(7)}")
    let lit: HashMap[i32, i32, Minted] = [1: 7, 2: 8, 3: 9]
    print(f"{lit.get(1).unwrap()} {lit.get(2).unwrap()} {lit.get(3).unwrap()}")
    // The constructor form: three arguments parse as a multi-index and
    // name the type when the base is one.
    var built = HashMap[i32, str, Minted].new()
    built.insert(3, "c")
    print(f"{built.get(3).unwrap()} {built.len()}")
