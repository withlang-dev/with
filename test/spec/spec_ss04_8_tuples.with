// Spec test: Section 4.8 - Tuples.

fn divmod_tuple(a: i32, b: i32) -> (i32, i32): (a / b, a % b)

fn test_tuple_construction_and_destructuring:
    let pair = (42, "hello")
    let (n, s) = pair
    assert(n == 42)
    assert(s == "hello")

fn test_tuple_access_by_index:
    let t = (1, 2, 3)
    assert(t.0 == 1)
    assert(t.2 == 3)

fn test_tuple_return_from_function:
    let (q, r) = divmod_tuple(17, 5)
    assert(q == 3)
    assert(r == 2)

fn test_nested_tuple_destructuring:
    let ((a, b), c) = ((1, 2), 3)
    assert(a == 1)
    assert(b == 2)
    assert(c == 3)

fn test_tuple_destructuring_in_for_loops:
    let pairs = [(1, "a"), (2, "b")]
    var total = 0
    for (n, s) in pairs:
        total += n
        assert(s.len() == 1)
    assert(total == 3)

fn test_tuple_is_copy_when_all_elements_are_copy:
    let t: (i32, bool) = (1, true)
    let t2 = t
    assert(t.0 == 1)
    assert(t2.1)
