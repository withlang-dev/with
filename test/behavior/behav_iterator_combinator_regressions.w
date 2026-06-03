//! expect-stdout: ok

fn test_vec_filter_uses_element_type:
    let words: Vec[str] = Vec.new()
    words.push("a")
    words.push("bb")
    words.push("c")

    let short = words.filter(s => s.len32() == 1)
    assert(short.len() == 2)
    assert(short.get(0) == "a")
    assert(short.get(1) == "c")

fn test_vec_fold_uses_accumulator_and_element_types:
    let nums: Vec[i64] = Vec.new()
    nums.push(10i64)
    nums.push(20i64)
    nums.push(30i64)

    let sum = nums.fold(0i64, (acc, x) => acc + x)
    assert(sum == 60i64)

fn main:
    test_vec_filter_uses_element_type()
    test_vec_fold_uses_accumulator_and_element_types()
    print("ok")
