// Test: HashMap[i32, str] with integer keys
fn main() -> i32 =
    var m: HashMap[i32, str] = HashMap.new()

    m.insert(1, "one")
    m.insert(2, "two")
    m.insert(3, "three")
    assert(m.len() == 3)

    // Get with integer key
    assert(m.get(1).unwrap() == "one")
    assert(m.get(2).unwrap() == "two")
    assert(m.get(3).unwrap() == "three")

    // Contains
    assert(m.contains(2))

    // Update
    m.insert(2, "TWO")
    assert(m.get(2).unwrap() == "TWO")
    assert(m.len() == 3)

    // Remove
    m.remove(1)
    assert(m.len() == 2)
    assert(m.get(1).is_none())

    0
