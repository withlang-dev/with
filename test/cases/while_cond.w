// Test: while loop with complex conditions
fn main -> i32:
    // Count up while multiple conditions hold
    var x: i32 = 0
    var y: i32 = 100
    while x < 50 and y > 50:
        x += 1
        y -= 1

    // x=50, y=50 when loop ends (x < 50 fails)
    assert(x == 50)
    assert(y == 50)

    // Nested while loops
    var sum: i32 = 0
    var i: i32 = 0
    while i < 3:
        var j: i32 = 0
        while j < 3:
            sum += i + j
            j += 1
        i += 1

    // (0+0)+(0+1)+(0+2)+(1+0)+(1+1)+(1+2)+(2+0)+(2+1)+(2+2) = 18
    assert(sum == 18)

    // while with or condition
    var k: i32 = 10
    while k > 5 or k == 5:
        k -= 1
    assert(k == 4)

