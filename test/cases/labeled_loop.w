// Labeled loops and breaks
fn main -> i32:
    var result = 0

    // Test 1: labeled for with break
    var sum1 = 0
    'outer: for i in 0..3
        for j in 0..3
            if i == 1 and j == 1: break 'outer
            sum1 = sum1 + 1
    // i=0: j=0,1,2 -> 3; i=1: j=0 -> 1; then break = 4
    if sum1 != 4: result = result + 1

    // Test 2: labeled for with continue
    var sum2 = 0
    'skip: for i in 0..3
        for j in 0..3
            if j == 1: continue 'skip
            sum2 = sum2 + 1
    // each i: only j=0 runs (+1), then continue outer. 3*1 = 3
    if sum2 != 3: result = result + 1

    // Test 3: labeled while with break
    var sum3 = 0
    var i = 0
    'done: while i < 5
        if sum3 >= 3: break 'done
        sum3 = sum3 + 1
        i = i + 1
    if sum3 != 3: result = result + 1

    println(result)
    result
