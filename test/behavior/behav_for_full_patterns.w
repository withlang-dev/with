//! expect-stdout: ok

type User {
    name: str,
    age: i32,
}

fn test_struct_pattern:
    let users = [
        User { name: "Ada", age: 36 },
        User { name: "Grace", age: 85 },
    ]
    var total = 0
    for { age, .. } in users:
        total = total + age
    assert(total == 121)

fn test_enum_pattern_filters:
    let opts: Vec[?i32] = Vec.new()
    opts.push(Some(1))
    opts.push(None)
    opts.push(Some(4))
    opts.push(None)
    opts.push(Some(8))
    var shorthand_sum = 0
    for .Some(v) in opts:
        shorthand_sum = shorthand_sum + v
    assert(shorthand_sum == 13)

    var qualified_sum = 0
    for Option.Some(v) in opts:
        qualified_sum = qualified_sum + v
    assert(qualified_sum == 13)

fn test_slice_rest_pattern:
    let rows = [
        [1, 2, 3],
        [4, 5, 6],
    ]
    var total = 0
    for [first, ..rest] in rows:
        total = total + first + rest
    assert(total == 9)

fn test_refutable_range_pattern_skips:
    var sum = 0
    for 2..=4 in 0..6:
        sum = sum + 1
    assert(sum == 3)

fn test_vec_refutable_pattern_skips:
    let nums: Vec[i32] = Vec.new()
    nums.push(1)
    nums.push(2)
    nums.push(3)
    nums.push(4)
    nums.push(5)
    var sum = 0
    for 2..=4 in nums:
        sum = sum + 1
    assert(sum == 3)

fn main:
    test_struct_pattern()
    test_enum_pattern_filters()
    test_slice_rest_pattern()
    test_refutable_range_pattern_skips()
    test_vec_refutable_pattern_skips()
    print("ok")
