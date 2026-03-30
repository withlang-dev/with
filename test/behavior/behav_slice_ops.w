//! expect-stdout: ok

// Tests: Vec as dynamic slice, push/get/len, Vec iteration,
//        Vec in functions, Vec accumulation

fn test_vec_basic:
    let v: Vec[i32] = Vec.new()
    v.push(10)
    v.push(20)
    v.push(30)
    assert(v.len() == 3)
    assert(v.get(0) == 10)
    assert(v.get(1) == 20)
    assert(v.get(2) == 30)

fn test_vec_empty:
    let v: Vec[i32] = Vec.new()
    assert(v.len() == 0)

fn test_vec_single:
    let v: Vec[i32] = Vec.new()
    v.push(42)
    assert(v.len() == 1)
    assert(v.get(0) == 42)

fn test_vec_many_pushes:
    let v: Vec[i32] = Vec.new()
    var i = 0
    while i < 100:
        v.push(i)
        i = i + 1
    assert(v.len() == 100)
    assert(v.get(0) == 0)
    assert(v.get(99) == 99)

fn test_vec_sum:
    let v: Vec[i32] = Vec.new()
    v.push(1)
    v.push(2)
    v.push(3)
    v.push(4)
    v.push(5)
    var sum = 0
    var i = 0
    while i < v.len():
        sum = sum + v.get(i)
        i = i + 1
    assert(sum == 15)

fn test_vec_for_loop:
    let v: Vec[i32] = Vec.new()
    v.push(10)
    v.push(20)
    v.push(30)
    var sum = 0
    for val in v:
        sum = sum + val
    assert(sum == 60)

fn vec_sum(v: Vec[i32]) -> i32:
    var total = 0
    for val in v:
        total = total + val
    total

fn test_vec_in_function:
    let v: Vec[i32] = Vec.new()
    v.push(5)
    v.push(10)
    v.push(15)
    assert(vec_sum(v) == 30)

fn main:
    test_vec_basic()
    test_vec_empty()
    test_vec_single()
    test_vec_many_pushes()
    test_vec_sum()
    test_vec_for_loop()
    test_vec_in_function()
    print("ok")
