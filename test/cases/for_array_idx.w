// Test: for loop over array elements
fn main() -> i32 =
    // basic for-in over array
    let arr = [10, 20, 30, 40, 50]
    var sum: i32 = 0
    for x in arr:
        sum += x
    assert(sum == 150)

    // for-in with condition
    let nums = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    var even_sum: i32 = 0
    for n in nums:
        if n % 2 == 0:
            even_sum += n
    assert(even_sum == 30)

    // for-in accumulating count
    let items = [5, 10, 15, 20, 25]
    var count: i32 = 0
    for x in items:
        count += 1
    assert(count == 5)

    // for-in with larger values
    let big = [100, 200, 300]
    var total: i32 = 0
    for v in big:
        total += v
    assert(total == 600)

    // nested computation in for body
    let data = [1, 2, 3, 4]
    var squared_sum: i32 = 0
    for d in data:
        squared_sum += d * d
    assert(squared_sum == 30)

    println("all for array idx tests passed")
    0
