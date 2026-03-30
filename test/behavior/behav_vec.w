//! expect-stdout: ok

// Behavior test: Vec operations
// Tests: push, get, len (testing the built-in Vec type used throughout)

fn test_vec_basic:
    var v = Vec[i32].new()
    v.push(10)
    v.push(20)
    v.push(30)
    assert(v.len() == 3)
    assert(v.get(0) == 10)
    assert(v.get(1) == 20)
    assert(v.get(2) == 30)

fn test_vec_empty:
    var v = Vec[i32].new()
    assert(v.len() == 0)

fn test_vec_large:
    var v = Vec[i32].new()
    for i in 0..100:
        v.push(i)
    assert(v.len() == 100)
    assert(v.get(0) == 0)
    assert(v.get(50) == 50)
    assert(v.get(99) == 99)

fn test_vec_push_pop_pattern:
    // Simulate stack behavior with Vec
    var stack = Vec[i32].new()
    stack.push(1)
    stack.push(2)
    stack.push(3)
    assert(stack.len() == 3)
    assert(stack.get(2) == 3)  // top of stack

fn main:
    test_vec_basic()
    test_vec_empty()
    test_vec_large()
    test_vec_push_pop_pattern()
    print("ok")
