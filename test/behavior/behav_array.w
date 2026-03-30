//! expect-stdout: ok

// Behavior test: arrays
// Tests: array literals, indexing, iteration

fn test_array_literal:
    let a = [1, 2, 3]
    assert(a[0] == 1)
    assert(a[1] == 2)
    assert(a[2] == 3)

fn test_array_single:
    let a = [42]
    assert(a[0] == 42)

fn test_array_five_elements:
    let a = [10, 20, 30, 40, 50]
    assert(a[0] == 10)
    assert(a[2] == 30)
    assert(a[4] == 50)

fn test_array_iteration:
    let a = [1, 2, 3, 4]
    var sum = 0
    for x in a:
        sum = sum + x
    assert(sum == 10)

fn test_array_iteration_larger:
    let a = [10, 20, 30]
    var sum = 0
    for x in a:
        sum = sum + x
    assert(sum == 60)

fn test_array_negative_values:
    let a = [-1, 0, 1]
    assert(a[0] == -1)
    assert(a[1] == 0)
    assert(a[2] == 1)

fn main:
    test_array_literal()
    test_array_single()
    test_array_five_elements()
    test_array_iteration()
    test_array_iteration_larger()
    test_array_negative_values()
    print("ok")
