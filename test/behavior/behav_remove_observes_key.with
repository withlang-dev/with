//! expect-stdout: k1 k1 k1 k1 4 ok

// remove observes its key (`&K`/`&T`), like get and contains (D110): the
// caller keeps the key, and only the stored key is dropped. #2265 made the
// consumed key a "use of moved value"; a parameter's mode is what the
// callee does with it, and remove only reads its key.
use std.collections.HashMap
use std.collections.HashSet
use std.collections.BTreeMap
use std.collections.BTreeSet

fn key(): f"k{1}"

fn main:
    var m: HashMap[str, i32] = HashMap.new()
    var s: HashSet[str] = HashSet.new()
    var bm: BTreeMap[str, i32] = BTreeMap.new()
    var bs: BTreeSet[str] = BTreeSet.new()
    m.insert(key(), 1)
    s.insert(key())
    bm.insert(key(), 3)
    bs.insert(key())
    let a = key()
    let mv = m.remove(a)
    let b = key()
    let sv = s.remove(b)
    let c = key()
    let bv = bm.remove(c)
    let d = key()
    let tv = bs.remove(d)
    print(f"{a} {b} {c} {d} {mv.unwrap() + bv.unwrap()} " ++ (if sv and tv and m.len() == 0 and s.len() == 0 and bm.len() == 0 and bs.len() == 0: "ok" else: "bad"))
