// Test: HashSet[T] built-in collection
fn main() -> i32 =
    var s: HashSet[str] = HashSet.new()

    // Empty check
    assert(s.len() == 0)
    assert(s.is_empty())

    // Insert
    s.insert("apple")
    s.insert("banana")
    s.insert("cherry")
    assert(s.len() == 3)

    // Contains
    assert(s.contains("apple"))
    assert(s.contains("banana"))
    assert(s.contains("cherry"))

    // Duplicate insert doesn't increase len
    s.insert("apple")
    assert(s.len() == 3)

    // Remove
    s.remove("banana")
    assert(s.len() == 2)
    assert(s.contains("apple"))
    assert(s.contains("cherry"))

    // Integer set
    var nums: HashSet[i32] = HashSet.new()
    nums.insert(10)
    nums.insert(20)
    nums.insert(30)
    assert(nums.len() == 3)
    assert(nums.contains(20))
    nums.remove(20)
    assert(nums.len() == 2)

    0
