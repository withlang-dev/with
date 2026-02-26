// Test vector push, len, and iteration
fn main -> i32:
    var v = Vec.new()
    v.push(10)
    v.push(20)
    v.push(30)
    println(v.len())
    // Iterate and sum
    var sum = 0
    for x in v
        sum = sum + x
    println(sum)
