//! expect-stdout: ok

// Behavior test: HashMap
// Tests: basic HashMap operations (the HashMap used throughout compiler)

fn test_hashmap_basic:
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("hello", 1)
    m.insert("world", 2)
    let v1 = m.get("hello")
    assert(v1.unwrap() == 1)
    let v2 = m.get("world")
    assert(v2.unwrap() == 2)

fn test_hashmap_overwrite:
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("key", 10)
    let v1 = m.get("key")
    assert(v1.unwrap() == 10)
    m.insert("key", 20)
    let v2 = m.get("key")
    assert(v2.unwrap() == 20)

fn test_hashmap_missing:
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("present", 42)
    let v = m.get("missing")
    assert(v.is_none())

fn test_hashmap_many:
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("a", 1)
    m.insert("b", 2)
    m.insert("c", 3)
    m.insert("d", 4)
    m.insert("e", 5)
    assert(m.get("a").unwrap() == 1)
    assert(m.get("c").unwrap() == 3)
    assert(m.get("e").unwrap() == 5)

fn main:
    test_hashmap_basic()
    test_hashmap_overwrite()
    test_hashmap_missing()
    test_hashmap_many()
    println("ok")
