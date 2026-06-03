//! expect-stdout: ok
// Spec test: Section 13.6 — Comprehensions.

fn assert_vec_i32(xs: Vec[i32], a: i32, b: i32, c: i32):
    assert(xs.len() == 3)
    assert(xs.get(0) == a)
    assert(xs.get(1) == b)
    assert(xs.get(2) == c)

fn test_basic_range:
    let squares = [x * x for x in 0..5]
    assert(squares.len() == 5)
    assert(squares.get(0) == 0)
    assert(squares.get(1) == 1)
    assert(squares.get(2) == 4)
    assert(squares.get(3) == 9)
    assert(squares.get(4) == 16)

fn test_filter:
    let evens = [x for x in 0..8 if x % 2 == 0]
    assert(evens.len() == 4)
    assert(evens.get(0) == 0)
    assert(evens.get(1) == 2)
    assert(evens.get(2) == 4)
    assert(evens.get(3) == 6)

fn test_nested:
    let pairs = [x * 10 + y for x in 0..3 for y in 0..3 if x != y]
    assert(pairs.len() == 6)
    assert(pairs.get(0) == 1)
    assert(pairs.get(1) == 2)
    assert(pairs.get(2) == 10)
    assert(pairs.get(3) == 12)
    assert(pairs.get(4) == 20)
    assert(pairs.get(5) == 21)

fn test_vec_source:
    let nums: Vec[i32] = Vec.new()
    nums.push(2)
    nums.push(4)
    nums.push(6)
    let doubled = [x * 2 for x in nums]
    assert_vec_i32(doubled, 4, 8, 12)

fn test_pattern_binding:
    let src = [(1, 2), (3, 4), (5, 6)]
    let sums = [a + b for (a, b) in src]
    assert_vec_i32(sums, 3, 7, 11)

fn main:
    test_basic_range()
    test_filter()
    test_nested()
    test_vec_source()
    test_pattern_binding()
    print("ok")
