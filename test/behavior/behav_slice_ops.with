//! expect-stdout: ok

// Tests: List as dynamic slice, push/get/len, List iteration,
//        List in functions, List accumulation

fn test_list_basic:
    let v: List[i32] = List.new()
    v.push(10)
    v.push(20)
    v.push(30)
    assert(v.len() == 3)
    assert(v[0] == 10)
    assert(v[1] == 20)
    assert(v[2] == 30)

fn test_list_empty:
    let v: List[i32] = List.new()
    assert(v.len() == 0)

fn test_list_single:
    let v: List[i32] = List.new()
    v.push(42)
    assert(v.len() == 1)
    assert(v[0] == 42)

fn test_list_many_pushes:
    let v: List[i32] = List.new()
    var i: i32 = 0
    while i < 100:
        v.push(i)
        i = i + 1
    assert(v.len() == 100)
    assert(v[0] == 0)
    assert(v[99] == 99)

fn test_list_sum:
    let v: List[i32] = List.new()
    v.push(1)
    v.push(2)
    v.push(3)
    v.push(4)
    v.push(5)
    var sum = 0
    var i = 0
    while i < v.len():
        sum = sum + v[i]
        i = i + 1
    assert(sum == 15)

fn test_list_for_loop:
    let v: List[i32] = List.new()
    v.push(10)
    v.push(20)
    v.push(30)
    var sum = 0
    for val in v:
        sum = sum + val
    assert(sum == 60)

fn list_sum(v: List[i32]) -> i32:
    var total: i32 = 0
    for val in v:
        total = total + val
    total

fn test_list_in_function:
    let v: List[i32] = List.new()
    v.push(5)
    v.push(10)
    v.push(15)
    assert(list_sum(v) == 30)

fn main:
    test_list_basic()
    test_list_empty()
    test_list_single()
    test_list_many_pushes()
    test_list_sum()
    test_list_for_loop()
    test_list_in_function()
    print("ok")
