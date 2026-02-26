fn main() -> i32 =
    var v: Vec[i32] = Vec.new()
    var i = 0
    while i < 5
        v.push(i * 10)
        i = i + 1
    var sum = 0
    for x in v
        sum = sum + x
    println(sum)
    println(v.len())
    0
