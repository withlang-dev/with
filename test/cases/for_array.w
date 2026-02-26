fn main -> i32:
    let arr = [10, 20, 30, 40, 50]
    var sum: i32 = 0
    for x in arr:
        sum += x
    assert(sum == 150)
