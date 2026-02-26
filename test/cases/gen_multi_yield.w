// Test: generator function with multiple yield points and parameters
gen fn alternating(a: i32, b: i32, count: i32) -> i32:
    var i: i32 = 0
    while i < count:
        if i % 2 == 0:
            yield a
        else
            yield b
        i += 1

gen fn countdown_by(start: i32, step: i32) -> i32:
    var val: i32 = start
    while val > 0:
        yield val
        val -= step

fn main -> i32:
    // Test alternating generator
    var iter1 = alternating(10, 20, 6)
    var sum1: i32 = 0
    for x in iter1:
        sum1 += x
    // 10+20+10+20+10+20 = 90
    assert(sum1 == 90)

    // Test countdown by step
    var iter2 = countdown_by(10, 3)
    var sum2: i32 = 0
    var count: i32 = 0
    for x in iter2:
        sum2 += x
        count += 1
    // 10, 7, 4, 1 => sum = 22, count = 4
    assert(sum2 == 22)
    assert(count == 4)

    println("all gen_multi_yield tests passed")
