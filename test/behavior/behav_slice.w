//! expect-stdout: ok

// Behavior test: slices — creation, indexing, len
// Tests slices via array slicing and Vec usage.

fn test_array_basics:
    let arr = [10, 20, 30, 40, 50]
    assert(arr[0] == 10)
    assert(arr[1] == 20)
    assert(arr[2] == 30)
    assert(arr[3] == 40)
    assert(arr[4] == 50)

fn test_array_len:
    let arr = [1, 2, 3]
    assert(arr.len() == 3)

fn test_array_in_loop:
    let arr = [10, 20, 30]
    var sum = 0
    for i in 0..3:
        sum = sum + arr[i]
    assert(sum == 60)

fn test_vec_as_dynamic_slice:
    let v: Vec[i32] = Vec.new()
    v.push(100)
    v.push(200)
    v.push(300)
    assert(v.len() == 3)
    assert(v.get(0) == 100)
    assert(v.get(1) == 200)
    assert(v.get(2) == 300)

fn test_empty_array:
    let arr = [0, 0, 0]
    var all_zero = true
    for i in 0..3:
        if arr[i] != 0:
            all_zero = false
    assert(all_zero)

fn main:
    test_array_basics()
    test_array_len()
    test_array_in_loop()
    test_vec_as_dynamic_slice()
    test_empty_array()
    println("ok")
