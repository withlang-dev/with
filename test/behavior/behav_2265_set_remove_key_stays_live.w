//! expect-stdout: k1 k1

// #2265 asserted that HashSet.remove consumed its key, so a later use was "use of
// moved value". D110 (Eric, 2026-10-08): a parameter's mode is what the
// callee does with it; HashSet.remove only reads its key, so it observes it and
// the caller's binding stays live with its original text.
use std.collections.HashMap
use std.collections.HashSet

fn key(): f"k{1}"

fn main:
    var m: HashMap[str, i32] = HashMap.new()
    var s: HashSet[str] = HashSet.new()
    m.insert(key(), 1)
    s.insert(key())
    let a = key()
    s.remove(a)
    print(a ++ " " ++ a)
