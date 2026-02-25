// Test: for loop with index binding
fn main() -> i32 =
    let arr = [10, 20, 30, 40, 50]
    var sum: i32 = 0
    var idx_sum: i64 = 0
    for x, i in arr:
        sum += x
        idx_sum += i
    assert(sum == 150)
    assert(idx_sum == 10)

    let names = [100, 200, 300]
    var weighted: i64 = 0
    for val, idx in names:
        weighted += val * (idx + 1)
    assert(weighted == 1400)

    println("all for index tests passed")
    0
