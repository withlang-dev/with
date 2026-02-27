// Test: while loop with break and continue
fn main -> i32:
    // basic while with break
    var i: i32 = 0
    while true:
        i += 1
        if i == 10 then break
    assert(i == 10)

    // while with continue (skip even numbers)
    var j: i32 = 0
    var odd_sum: i32 = 0
    while j < 10:
        j += 1
        if j % 2 == 0 then continue
        odd_sum += j
    assert(odd_sum == 25)

    // nested while with break
    var outer: i32 = 0
    var count: i32 = 0
    while outer < 5:
        var inner: i32 = 0
        while inner < 5:
            inner += 1
            if inner == 3 then break
            count += 1
        outer += 1
    assert(count == 10)

    // while counting down
    var k: i32 = 100
    while k > 0:
        k -= 10
    assert(k == 0)

    // while with both break and continue
    var m: i32 = 0
    var total: i32 = 0
    while m < 20:
        m += 1
        if m % 3 == 0 then continue
        if m > 10 then break
        total += m

    assert(total == 37)

    println("all while break val tests passed")
