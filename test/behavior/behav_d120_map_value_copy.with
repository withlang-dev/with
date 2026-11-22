//! expect-stdout: a 2 b 3
//! expect-stdout: a 2 b 3 c 1
//! expect-stdout: names 2 kept 1
//! expect-stdout: a.x 1 b.x 10
//! expect-stdout: total 3
//! expect-stdout: drained 3 left 3
//! expect-stdout: ok

// D120 stage 2 (§2.3): a HashMap or HashSet of values is a value. `let b =
// a` copies it in O(1) (the table is shared under a count); the first
// mutation of a shared table copies it, so `a` never sees `b`'s insert. A
// map of str keys and str values is a map of values too: the copy retains
// each entry. Passing a value map copies it, so the caller still has it.
use std.collections.HashMap
use std.collections.HashSet

fn total(m: HashMap[str, i32]) -> i32:
    var s = 0
    for (_, v) in m: s += v
    s

fn main:
    var a: HashMap[str, i32] = HashMap.new()
    a.insert("x", 1)
    a.insert("y", 2)
    var b = a
    b.insert("z", 3)
    print(f"a {a.len()} b {b.len()}")
    var c = b
    c.clear()
    c.insert("w", 4)
    print(f"a {a.len()} b {b.len()} c {c.len()}")
    var names: HashSet[str] = HashSet.new()
    names.insert("p")
    names.insert("q")
    var kept = names
    kept.remove("p")
    print(f"names {names.len()} kept {kept.len()}")
    var words: HashMap[str, str] = HashMap.new()
    words.insert("k", "v")
    var more = words
    more.insert("k2", "v2")
    b.insert("x", 10)
    print(f"a.x {a.get(\"x\").unwrap()} b.x {b.get(\"x\").unwrap()}")
    print(f"total {total(a)}")
    var drained = 0
    for (_, _) in b.drain(): drained += 1
    print(f"drained {drained} left {more.len() + words.len()}")
    print(f"{a.len() == 2 and b.len() == 0}".replace("true", "ok"))
