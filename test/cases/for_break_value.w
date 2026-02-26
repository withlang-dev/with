// Test: break with value in various loop types

fn find_first_gt(threshold: i32) -> i32 =
    var i = 0
    loop:
        if i * i > threshold then break i
        i = i + 1

fn main() -> i32 =
    // Find first n where n*n > 100
    let x = find_first_gt(100)
    println(x)
    assert(x == 11)

    // Break with value in while loop
    var j = 0
    let y = loop:
        if j >= 5 then break j * 2
        j = j + 1
    println(y)
    assert(y == 10)

    0
