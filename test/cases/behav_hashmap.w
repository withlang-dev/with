//! expect-stdout: ok

// Behavior test: HashMap
// Tests: basic HashMap operations (the HashMap used throughout compiler)

fn test_hashmap_basic:
    var m = HashMap.new()
    HashMap.put(m, "hello", 1)
    HashMap.put(m, "world", 2)
    assert(HashMap.get(m, "hello") == 1)
    assert(HashMap.get(m, "world") == 2)

fn test_hashmap_overwrite:
    var m = HashMap.new()
    HashMap.put(m, "key", 10)
    assert(HashMap.get(m, "key") == 10)
    HashMap.put(m, "key", 20)
    assert(HashMap.get(m, "key") == 20)

fn test_hashmap_missing:
    var m = HashMap.new()
    HashMap.put(m, "present", 42)
    assert(HashMap.get(m, "missing") == 0)

fn test_hashmap_many:
    var m = HashMap.new()
    HashMap.put(m, "a", 1)
    HashMap.put(m, "b", 2)
    HashMap.put(m, "c", 3)
    HashMap.put(m, "d", 4)
    HashMap.put(m, "e", 5)
    assert(HashMap.get(m, "a") == 1)
    assert(HashMap.get(m, "c") == 3)
    assert(HashMap.get(m, "e") == 5)

fn main:
    test_hashmap_basic()
    test_hashmap_overwrite()
    test_hashmap_missing()
    test_hashmap_many()
    println("ok")
