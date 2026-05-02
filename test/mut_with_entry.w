// Test: §10 scoped with-access via HashMapEntry

fn test_entry_or_insert_new:
    var m: HashMap[str, i32] = HashMap.new()
    with m.entry("x") as mut e:
        e.or_insert(42)
    assert(m.get("x").unwrap() == 42)

fn test_entry_or_insert_existing:
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("x", 10)
    with m.entry("x") as mut e:
        e.or_insert(99)
    assert(m.get("x").unwrap() == 10)

fn test_entry_set:
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("a", 1)
    with m.entry("a") as mut e:
        e.set(100)
    assert(m.get("a").unwrap() == 100)

fn test_entry_get:
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("k", 55)
    with m.entry("k") as mut e:
        let v = e.get()
        assert(v == 55)
