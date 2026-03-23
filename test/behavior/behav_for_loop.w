//! expect-stdout: ok

// Tests: for over array, for with break, for with continue,
//        nested for, for accumulator, for with index

fn test_for_basic:
    var sum = 0
    let arr = [1, 2, 3, 4, 5]
    for v in arr:
        sum = sum + v
    assert(sum == 15)

fn test_for_break:
    var last = 0
    let arr = [10, 20, 30, 40, 50]
    for v in arr:
        last = v
        if v == 30:
            break
    assert(last == 30)

fn test_for_continue:
    var sum = 0
    let arr = [1, 2, 3, 4, 5, 6]
    for v in arr:
        if v % 2 == 0:
            continue
        sum = sum + v
    // 1 + 3 + 5 = 9
    assert(sum == 9)

fn test_for_empty_array:
    var count = 0
    let arr: [i32; 0] = []
    for v in arr:
        count = count + 1
    assert(count == 0)

fn test_for_single_element:
    var total = 0
    let arr = [42]
    for v in arr:
        total = total + v
    assert(total == 42)

fn test_nested_for:
    var sum = 0
    let outer = [1, 2, 3]
    let inner = [10, 20]
    for a in outer:
        for b in inner:
            sum = sum + a * b
    // 1*10 + 1*20 + 2*10 + 2*20 + 3*10 + 3*20 = 30 + 60 + 90 = 180
    assert(sum == 180)

fn test_for_break_in_nested:
    var count = 0
    let outer = [1, 2, 3]
    let inner = [10, 20, 30]
    for a in outer:
        for b in inner:
            count = count + 1
            if b == 20:
                break
    // Each outer iteration: inner breaks at b==20, so 2 iterations
    // 3 outer * 2 inner = 6
    assert(count == 6)

fn test_for_accumulate_product:
    var product = 1
    let arr = [2, 3, 4]
    for v in arr:
        product = product * v
    assert(product == 24)

fn test_for_find_max:
    let arr = [3, 7, 2, 9, 4]
    var max_val = arr[0]
    for v in arr:
        if v > max_val:
            max_val = v
    assert(max_val == 9)

fn main:
    test_for_basic()
    test_for_break()
    test_for_continue()
    test_for_empty_array()
    test_for_single_element()
    test_nested_for()
    test_for_break_in_nested()
    test_for_accumulate_product()
    test_for_find_max()
    println("ok")
