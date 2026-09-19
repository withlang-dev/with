//! expect-stdout: ok

// #1189: HashMap.remove / HashSet.remove transfer the stored key out of the
// table as well as the value. The runtime only cleared the slot, so a key
// that owns memory leaked (16 bytes per removal). Run under --debug-alloc;
// zero leaks.

use std.collections.HashMap
use std.collections.HashSet

fn main:
    var m: HashMap[str, str] = HashMap.new()
    m.insert("alpha".to_owned(), "one".to_owned())
    m.insert("beta".to_owned(), "two".to_owned())
    m.insert("gamma".to_owned(), "three".to_owned())
    let gone = m.remove("beta").unwrap()
    assert(gone == "two")
    assert(m.len() == 2)
    assert(m.remove("beta").is_none())
    assert(m.remove("missing").is_none())
    assert(m.get("alpha").unwrap() == "one")
    assert(m.get("gamma").unwrap() == "three")
    assert(m.remove("alpha").unwrap() == "one")
    assert(m.remove("gamma").unwrap() == "three")
    assert(m.len() == 0)
    m.insert("again".to_owned(), "yes".to_owned())
    assert(m.get("again").unwrap() == "yes")

    var ages: HashMap[str, i32] = HashMap.new()
    ages.insert("ada".to_owned(), 36)
    assert(ages.remove("ada").unwrap() == 36)
    assert(ages.remove("ada").is_none())

    var squares: HashMap[i32, str] = HashMap.new()
    squares.insert(2, "four".to_owned())
    assert(squares.remove(2).unwrap() == "four")

    var seen: HashSet[str] = HashSet.new()
    seen.insert("x".to_owned())
    seen.insert("y".to_owned())
    assert(seen.remove("x"))
    assert(not seen.remove("x"))
    assert(seen.contains("y"))
    print("ok")
