// Test HashSet operations
fn main() -> i32 =
    var s: HashSet[i32] = HashSet.new()
    s.insert(1)
    s.insert(2)
    s.insert(3)
    s.insert(2)
    println(s.len())
    println(s.contains(1))
    println(s.contains(5))
    s.remove(2)
    println(s.len())
    0
