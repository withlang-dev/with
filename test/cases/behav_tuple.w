//! expect-stdout: ok

// Behavior test: tuples
// Tests: tuple creation, field access (.0, .1), passing to functions

fn sum_pair(p: (i32, i32)) -> i32:
    p.0 + p.1

fn test_tuple_creation:
    let t = (10, 20)
    assert(t.0 == 10)
    assert(t.1 == 20)

fn test_tuple_three:
    let t = (1, 2, 3)
    assert(t.0 == 1)
    assert(t.1 == 2)
    assert(t.2 == 3)

fn test_tuple_mixed_types:
    let t = (42, true)
    assert(t.0 == 42)
    assert(t.1 == true)

fn test_tuple_pass_to_fn:
    let p = (3, 7)
    assert(sum_pair(p) == 10)
    assert(sum_pair((100, 200)) == 300)

fn test_tuple_match:
    let p = (0, 5)
    let label = match p
        (0, 0) -> "origin"
        (0, _) -> "y-axis"
        (_, 0) -> "x-axis"
        _ -> "other"
    assert(label == "y-axis")

fn main:
    test_tuple_creation()
    test_tuple_three()
    test_tuple_mixed_types()
    test_tuple_pass_to_fn()
    test_tuple_match()
    println("ok")
