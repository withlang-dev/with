//! expect-stdout: ok

fn test_array_split:
    let xs = [10, 20, 30, 40]
    let (empty, all) = xs.split_at(0)
    assert(empty.len32() == 0)
    assert(all.len32() == 4)
    assert(all.get(0) == 10)
    let (left, right) = xs.split_at(2)
    assert(left.get(0) == 10)
    assert(left.get(1) == 20)
    assert(right.get(0) == 30)
    assert(right.get(1) == 40)
    let (all2, empty2) = xs.split_at(4)
    assert(all2.len() == 4)
    assert(empty2.len() == 0)

fn test_slice_split:
    let xs = [1, 2, 3, 4, 5]
    let mid = xs[1..4]
    let (left, right) = mid.split_at(1)
    assert(left.len() == 1)
    assert(right.len() == 2)
    assert(left.get(0) == 2)
    assert(right.get(0) == 3)
    assert(right.get(1) == 4)

fn test_vec_split:
    var xs = Vec.new()
    xs.push(5)
    xs.push(6)
    xs.push(7)
    xs.push(8)
    let (left, right) = xs.split_at(3)
    assert(left.len() == 3)
    assert(right.len() == 1)
    assert(left.get(2) == 7)
    assert(right.get(0) == 8)

fn test_range_split:
    var xs = Vec.new()
    xs.push(11)
    xs.push(12)
    xs.push(13)
    xs.push(14)
    let middle = xs.range(1..4)
    let (left, right) = middle.split_at(2)
    assert(left.get(0) == 12)
    assert(left.get(1) == 13)
    assert(right.get(0) == 14)

fn main:
    test_array_split()
    test_slice_split()
    test_vec_split()
    test_range_split()
    print("ok")
