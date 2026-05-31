// Spec test: Section 13.2 — HashMap Lookup Borrowing
// HashMap.get borrows the map (not the key) and returns an Option.

type User:
    name: str

fn test_get_returns_some:
    var map: HashMap[str, User] = HashMap.new()
    map.insert("admin", User { name: "Alice" })
    assert(map.get("admin").is_some())

fn test_get_missing_is_none:
    var map: HashMap[str, i32] = HashMap.new()
    map.insert("a", 1)
    assert(map.get("missing").is_none())

fn test_lookup_with_temporary_key:
    var map: HashMap[str, i32] = HashMap.new()
    map.insert("admin", 42)
    let key: str = "admin"
    let found = map.get(key)   // borrows the map, not the key
    assert(found.is_some())
