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

fn maybe_even_double(x: i32) -> Option[i32]:
    if x % 2 == 0: Some(x * 2) else: None

fn cmp_i32(a: i32, b: i32) -> i32:
    if a < b: -1 else if a > b: 1 else: 0

var FOREACH_TOTAL: i32 = 0

fn add_foreach(x: i32):
    FOREACH_TOTAL = FOREACH_TOTAL + x

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

fn test_filter_map_and_skip_adapters:
    let mapped = vec_1_to_4().iter()
        |> filter_map(maybe_even_double)
        |> collect[Vec]()
    assert(mapped.len() == 2)
    assert(mapped.get(0) == 4)
    assert(mapped.get(1) == 8)

    let window = vec_1_to_10().iter()
        |> drop(2)
        |> take_while(x => x < 7)
        |> drop_while(x => x < 5)
        |> collect[Vec]()
    assert(window.len() == 2)
    assert(window.get(0) == 5)
    assert(window.get(1) == 6)

fn test_enumerate_chain_zip_with_step_by:
    let enumerated = vec_123().iter()
        |> enumerate()
        |> collect[Vec]()
    assert(enumerated.len() == 3)
    let (i0, v0) = enumerated.get(0)
    let (i2, v2) = enumerated.get(2)
    assert(i0 == 0)
    assert(v0 == 1)
    assert(i2 == 2)
    assert(v2 == 3)

    let chained = vec_123().iter()
        |> chain(vec_1_to_4().iter())
        |> step_by(2)
        |> collect[Vec]()
    assert(chained.len() == 4)
    assert(chained.get(0) == 1)
    assert(chained.get(1) == 3)
    assert(chained.get(2) == 2)
    assert(chained.get(3) == 4)

    let combined = vec_123().iter()
        |> zip_with(vec_1_to_4().iter(), (a, b) => a * 10 + b)
        |> collect[Vec]()
    assert_vec_i32(combined, 11, 22, 33)

fn test_eager_consumers:
    let nums = vec_1_to_4()
    assert(nums.iter() |> product() == 24)
    assert((nums.iter() |> min()).unwrap() == 1)
    assert((nums.iter() |> max()).unwrap() == 4)
    assert((nums.iter() |> min_by(cmp_i32)).unwrap() == 1)
    assert((nums.iter() |> max_by(cmp_i32)).unwrap() == 4)
    assert((nums.iter() |> find(x => x == 3)).unwrap() == 3)
    assert((nums.iter() |> position(x => x == 3)).unwrap() == 2)
    assert(nums.iter() |> any(x => x == 4))
    assert(nums.iter() |> all(x => x > 0))
    assert(nums.iter() |> none(x => x < 0))

    FOREACH_TOTAL = 0
    nums.iter() |> for_each(add_foreach)
    assert(FOREACH_TOTAL == 10)

fn test_unzip:
    let pairs = vec_123().iter()
        |> zip(vec_1_to_4().iter())
    let (lefts, rights) = pairs.unzip()
    assert_vec_i32(lefts, 1, 2, 3)
    assert_vec_i32(rights, 1, 2, 3)

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
    test_filter_map_and_skip_adapters()
    test_enumerate_chain_zip_with_step_by()
    test_eager_consumers()
    test_unzip()
    print("ok")
