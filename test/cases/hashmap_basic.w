fn main() -> i32 =
    let mut m: HashMap[str, i32] = HashMap.new()
    m.insert("a", 1)
    m.insert("b", 2)
    m.insert("c", 3)
    println(m.get("a"))
    println(m.get("b"))
    println(m.contains("c"))
    println(m.contains("d"))
    0
