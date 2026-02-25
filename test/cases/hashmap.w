// Test: HashMap[K,V] built-in collection
fn main() -> i32 =
    var m: HashMap[str, i32] = HashMap.new()

    // Empty check
    assert(m.len() == 0)

    // Insert and retrieve
    m.insert("one", 1)
    m.insert("two", 2)
    m.insert("three", 3)
    assert(m.len() == 3)

    // Get returns Option
    let val = m.get("two")
    assert(val.unwrap() == 2)

    // Contains
    assert(m.contains("one"))
    assert(m.contains("three"))

    // Update existing key
    m.insert("two", 22)
    assert(m.get("two").unwrap() == 22)
    assert(m.len() == 3)

    // Remove
    m.remove("one")
    assert(m.len() == 2)

    // Get missing key returns None
    let missing = m.get("one")
    assert(missing.is_none())

    0
