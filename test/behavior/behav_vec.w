//! expect-stdout: ok

// Behavior test: List operations
// Tests: push, get, len (testing the built-in List type used throughout)

fn test_list_basic:
    var v = List[i32].new()
    v.push(10)
    v.push(20)
    v.push(30)
    assert(v.len() == 3)
    assert(v[0] == 10)
    assert(v[1] == 20)
    assert(v[2] == 30)

fn test_list_empty:
    var v = List[i32].new()
    assert(v.len() == 0)

fn test_list_large:
    var v = List[i32].new()
    for i in 0i32..100:
        v.push(i)
    assert(v.len() == 100)
    assert(v[0] == 0)
    assert(v[50] == 50)
    assert(v[99] == 99)

fn test_list_push_pop_pattern:
    // Simulate stack behavior with List
    var stack = List[i32].new()
    stack.push(1)
    stack.push(2)
    stack.push(3)
    assert(stack.len() == 3)
    assert(stack[2] == 3)  // top of stack

fn main:
    test_list_basic()
    test_list_empty()
    test_list_large()
    test_list_push_pop_pattern()
    print("ok")
