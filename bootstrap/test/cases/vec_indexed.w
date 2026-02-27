// Test Vec push, len, and pop
fn main -> i32:
    var v: Vec[i32] = Vec.new()
    v.push(10)
    v.push(20)
    v.push(30)
    println(v.len())
    let last = v.pop()
    println(last.unwrap())
    println(v.len())
