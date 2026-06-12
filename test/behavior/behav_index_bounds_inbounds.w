//! expect-stdout: ok

fn slice_sum(data: []i32) -> i32:
    data[0] + data[1] + data[2]

fn main:
    var arr = [10, 20, 30]
    assert(arr[0] == 10)
    arr[1] = 99
    assert(arr[1] == 99)

    let whole = arr[..]
    assert(whole.len() == 3)
    assert(slice_sum(whole) == 139)

    let tail = arr[1..3]
    assert(tail.len() == 2)
    assert(tail[0] == 99)
    assert(tail[1] == 30)

    let empty = arr[3..3]
    assert(empty.len() == 0)

    let values: Vec[i32] = Vec.new()
    values.push(4)
    values.push(5)
    values.push(6)
    assert(values[0] == 4)
    assert(values[2] == 6)

    print("ok")
