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

fn test_membership_filter:
    let primes = [2, 3, 5, 7, 11, 13]
    let prime_squares = [x * x for x in 1..=15 if x in primes]
    assert(prime_squares.len() == 6)
    assert(prime_squares.get(0) == 4)
    assert(prime_squares.get(1) == 9)
    assert(prime_squares.get(5) == 169)

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

fn test_hashset_target:
    let values: HashSet[i32] = [x for x in 0..6 if x % 2 == 0]
    assert(values.contains(0))
    assert(values.contains(2))
    assert(values.contains(4))
    assert(not values.contains(1))

fn test_hashmap_default:
    let pairs = [("a", 1), ("b", 2), ("a", 3)]
    let index = [k: v for (k, v) in pairs]
    assert(index.get("a").unwrap() == 3)
    assert(index.get("b").unwrap() == 2)
    assert(index.get("missing").is_none())

fn test_hashmap_expected_type:
    let pairs = [("a", 1), ("b", 2), ("a", 3)]
    let index: HashMap[str, i32] = [k: v * 2 for (k, v) in pairs]
    assert(index.get("a").unwrap() == 6)
    assert(index.get("b").unwrap() == 4)

fn test_map_nested_filter:
    let diagonal = [x: y for x in 0..4 for y in 0..4 if x == y and x > 0]
    assert(diagonal.get(0).is_none())
    assert(diagonal.get(1).unwrap() == 1)
    assert(diagonal.get(2).unwrap() == 2)
    assert(diagonal.get(3).unwrap() == 3)

fn main:
    test_basic_range()
    test_filter()
    test_membership_filter()
    test_nested()
    test_vec_source()
    test_pattern_binding()
    test_hashset_target()
    test_hashmap_default()
    test_hashmap_expected_type()
    test_map_nested_filter()
    print("ok")
