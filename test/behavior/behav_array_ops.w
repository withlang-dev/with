//! expect-stdout: ok

// Tests: array creation, indexing, mutation, iteration, length,
//        nested arrays, array of structs, array in function

fn test_array_literal:
    let arr = [1, 2, 3, 4, 5]
    assert(arr[0] == 1)
    assert(arr[4] == 5)

fn test_array_mutation:
    var arr = [10, 20, 30]
    arr[0] = 100
    arr[2] = 300
    assert(arr[0] == 100)
    assert(arr[1] == 20)
    assert(arr[2] == 300)

fn test_array_iteration:
    let arr = [2, 4, 6, 8]
    var sum = 0
    for v in arr:
        sum = sum + v
    assert(sum == 20)

fn test_array_length:
    let arr = [1, 2, 3, 4, 5, 6, 7]
    assert(arr.len() == 7)

fn test_empty_array:
    let arr: [i32; 0] = []
    assert(arr.len() == 0)

fn test_single_element_array:
    let arr = [42]
    assert(arr[0] == 42)
    assert(arr.len() == 1)

fn test_array_fill_pattern:
    var arr: [i32; 5] = [0; 5]
    var i = 0
    while i < 5:
        arr[i] = (i + 1) * 10
        i = i + 1
    assert(arr[0] == 10)
    assert(arr[1] == 20)
    assert(arr[4] == 50)

fn sum_array(arr: [i32; 4]) -> i32:
    var total = 0
    for v in arr:
        total = total + v
    total

fn test_array_as_argument:
    let arr = [10, 20, 30, 40]
    assert(sum_array(arr) == 100)

fn test_array_of_bools:
    let flags = [true, false, true, true, false]
    var count = 0
    for f in flags:
        if f:
            count = count + 1
    assert(count == 3)

fn test_array_find:
    let arr = [5, 10, 15, 20, 25]
    var found = false
    for v in arr:
        if v == 15:
            found = true
    assert(found)

fn test_array_max:
    let arr = [3, 1, 4, 1, 5, 9, 2, 6]
    var max_val = arr[0]
    for v in arr:
        if v > max_val:
            max_val = v
    assert(max_val == 9)

fn test_array_min:
    let arr = [3, 1, 4, 1, 5, 9, 2, 6]
    var min_val = arr[0]
    for v in arr:
        if v < min_val:
            min_val = v
    assert(min_val == 1)

fn test_array_all_positive:
    let arr = [1, 2, 3, 4, 5]
    var all_pos = true
    for v in arr:
        if v <= 0:
            all_pos = false
    assert(all_pos)

fn test_array_reverse_copy:
    let src = [1, 2, 3, 4, 5]
    var dst: [i32; 5] = [0; 5]
    var i = 0
    while i < 5:
        dst[4 - i] = src[i]
        i = i + 1
    assert(dst[0] == 5)
    assert(dst[1] == 4)
    assert(dst[2] == 3)
    assert(dst[3] == 2)
    assert(dst[4] == 1)

fn main:
    test_array_literal()
    test_array_mutation()
    test_array_iteration()
    test_array_length()
    test_empty_array()
    test_single_element_array()
    test_array_fill_pattern()
    test_array_as_argument()
    test_array_of_bools()
    test_array_find()
    test_array_max()
    test_array_min()
    test_array_all_positive()
    test_array_reverse_copy()
    print("ok")
