//! expect-stdout: ok
// Spec test: Section 13.3 — Collection Operations.

fn vec_123() -> Vec[i32]:
    let xs: Vec[i32] = Vec.new()
    xs.push(1)
    xs.push(2)
    xs.push(3)
    xs

fn vec_1_to_4() -> Vec[i32]:
    let xs: Vec[i32] = Vec.new()
    xs.push(1)
    xs.push(2)
    xs.push(3)
    xs.push(4)
    xs

fn vec_1_to_10() -> Vec[i32]:
    let xs: Vec[i32] = Vec.new()
    xs.push(1)
    xs.push(2)
    xs.push(3)
    xs.push(4)
    xs.push(5)
    xs.push(6)
    xs.push(7)
    xs.push(8)
    xs.push(9)
    xs.push(10)
    xs

fn assert_vec_i32(xs: Vec[i32], a: i32, b: i32, c: i32):
    assert(xs.len() == 3)
    assert(xs.get(0) == a)
    assert(xs.get(1) == b)
    assert(xs.get(2) == c)

fn test_reduce:
    let nums = vec_1_to_4()
    let sum = nums.iter() |> reduce((a, b) => a + b)
    assert(sum.is_some())
    assert(sum.unwrap() == 10)

fn test_fold:
    let nums = vec_123()
    let sum = nums.iter() |> fold(0, (acc, x) => acc + x)
    assert(sum == 6)

fn test_map_collect:
    let nums = vec_123()
    let doubled = nums.iter()
        |> map(x => x * 2)
        |> collect[Vec]()
    assert_vec_i32(doubled, 2, 4, 6)

fn test_flat_map:
    let lines: Vec[str] = Vec.new()
    lines.push("hello world")
    lines.push("foo bar")

    let words = lines.iter()
        |> flat_map(s => s.split(" "))
        |> collect[Vec]()

    assert(words.len() == 4)
    assert(words.get(0) == "hello")
    assert(words.get(1) == "world")
    assert(words.get(2) == "foo")
    assert(words.get(3) == "bar")

fn test_zip:
    let nums: Vec[i32] = Vec.new()
    nums.push(1)
    nums.push(2)

    let names: Vec[str] = Vec.new()
    names.push("a")
    names.push("b")

    let pairs = nums.iter()
        |> zip(names.iter())
        |> collect[Vec]()

    assert(pairs.len() == 2)
    let (n0, s0) = pairs.get(0)
    let (n1, s1) = pairs.get(1)
    assert(n0 == 1)
    assert(s0 == "a")
    assert(n1 == 2)
    assert(s1 == "b")

fn test_partition:
    let nums = vec_1_to_4()
    let (evens, odds) = nums.iter()
        |> partition(x => x % 2 == 0)

    assert(evens.len() == 2)
    assert(evens.get(0) == 2)
    assert(evens.get(1) == 4)
    assert(odds.len() == 2)
    assert(odds.get(0) == 1)
    assert(odds.get(1) == 3)

fn test_complex_pipeline:
    let nums = vec_1_to_10()
    let result = nums.iter()
        |> filter(x => x % 2 == 0)
        |> map(x => x * x)
        |> take(3)
        |> sum()

    assert(result == 56)

fn test_membership_filter_pipeline:
    let nums = vec_1_to_10()
    let values = nums.iter()
        |> filter(x => x in [2, 4, 6])
        |> collect[Vec]()
    assert_vec_i32(values, 2, 4, 6)

    let refs = nums.iter_ref()
        |> filter(x => *x in [2, 4, 6])
        |> map(x => *x)
        |> collect[Vec]()
    assert_vec_i32(refs, 2, 4, 6)

fn test_adapter_next:
    let nums = vec_123()
    let mapped = nums.iter()
        |> map(x => x * 10)

    let first = mapped.next()
    let second = mapped.next()
    let third = mapped.next()
    let done = mapped.next()

    assert(first.is_some())
    assert(first.unwrap() == 10)
    assert(second.is_some())
    assert(second.unwrap() == 20)
    assert(third.is_some())
    assert(third.unwrap() == 30)
    assert(done.is_none())

fn main:
    test_reduce()
    test_fold()
    test_map_collect()
    test_flat_map()
    test_zip()
    test_partition()
    test_complex_pipeline()
    test_membership_filter_pipeline()
    test_adapter_next()
    print("ok")
