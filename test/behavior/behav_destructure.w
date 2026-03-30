//! expect-stdout: ok

// Tests: tuple destructuring in let, tuple return destructuring,
//        destructuring in match arms

fn swap(a: i32, b: i32) -> (i32, i32):
    (b, a)

fn test_tuple_destructure:
    let (a, b) = swap(1, 2)
    assert(a == 2)
    assert(b == 1)

fn divide(a: i32, b: i32) -> (i32, i32):
    (a / b, a % b)

fn test_divmod_destructure:
    let (quot, rem) = divide(17, 5)
    assert(quot == 3)
    assert(rem == 2)

fn min_max(a: i32, b: i32) -> (i32, i32):
    if a < b: (a, b) else: (b, a)

fn test_min_max_destructure:
    let (lo, hi) = min_max(10, 3)
    assert(lo == 3)
    assert(hi == 10)
    let (lo2, hi2) = min_max(1, 100)
    assert(lo2 == 1)
    assert(hi2 == 100)

fn test_tuple_match_destructure:
    let p = (1, 2)
    let sum = match p
        (a, b) => a + b
    assert(sum == 3)

fn test_nested_tuple_access:
    let t = (10, 20, 30)
    assert(t.0 == 10)
    assert(t.1 == 20)
    assert(t.2 == 30)
    let sum = t.0 + t.1 + t.2
    assert(sum == 60)

fn main:
    test_tuple_destructure()
    test_divmod_destructure()
    test_min_max_destructure()
    test_tuple_match_destructure()
    test_nested_tuple_access()
    print("ok")
