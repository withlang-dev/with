//! expect-stdout: ok

// Tests: tuple creation, field access, tuple in match, tuple return,
//        tuple with mixed types, nested tuples

fn test_tuple_pair:
    let t = (10, 20)
    assert(t.0 == 10)
    assert(t.1 == 20)

fn test_tuple_triple:
    let t = (1, 2, 3)
    assert(t.0 == 1)
    assert(t.1 == 2)
    assert(t.2 == 3)

fn test_tuple_mixed:
    let t = (42, true, "hello")
    assert(t.0 == 42)
    assert(t.1 == true)
    assert(t.2 == "hello")

fn make_pair(a: i32, b: i32) -> (i32, i32):
    (a, b)

fn test_tuple_return:
    let p = make_pair(3, 7)
    assert(p.0 == 3)
    assert(p.1 == 7)

fn sum_pair(p: (i32, i32)) -> i32:
    p.0 + p.1

fn test_tuple_as_param:
    assert(sum_pair((10, 20)) == 30)
    assert(sum_pair(make_pair(5, 5)) == 10)

fn test_tuple_destructure:
    let (a, b) = make_pair(100, 200)
    assert(a == 100)
    assert(b == 200)

fn test_tuple_match:
    let p = (0, 5)
    let label = match p
        (0, 0) => "origin"
        (0, _) => "y-axis"
        (_, 0) => "x-axis"
        _ => "other"
    assert(label == "y-axis")

fn test_tuple_match_values:
    let p = (3, 4)
    let sum = match p
        (a, b) => a + b
    assert(sum == 7)

fn main:
    test_tuple_pair()
    test_tuple_triple()
    test_tuple_mixed()
    test_tuple_return()
    test_tuple_as_param()
    test_tuple_destructure()
    test_tuple_match()
    test_tuple_match_values()
    print("ok")
