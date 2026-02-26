fn main() -> i32 =
    let mut v = Vec.new()
    v.push(10)
    v.push(20)
    v.push(30)
    println(v.len())
    let last = v.pop()
    println(last)
    println(v.len())
    0
